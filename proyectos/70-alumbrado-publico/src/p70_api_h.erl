%% Handler JSON de la API. Un mismo modulo atiende las rutas; el segundo
%% elemento de la ruta (falla | mapa | falla_id | bitacora) indica cual es.
%%   POST  /api/lamparas/:id/falla   reporta una falla (se agrupa por luminaria)
%%                                   cuerpo opcional: {"prioridad":"alta|media|baja",
%%                                                     "fuente":"ciudadano|telemetria"}
%%   GET   /api/mapa/fallas          lista las fallas vigentes
%%   GET   /api/fallas/:id           detalle de una falla (:id = id de luminaria)
%%   PATCH /api/fallas/:id           {"accion":"asignar","cuadrilla":"c1"} | {"accion":"reparar"}
%%   GET   /api/bitacora?limite=N    ultimos eventos (mas reciente primero, N de 1 a 200)
-module(p70_api_h).

-export([init/2]).

-define(LIMITE_DEFECTO, 50).
-define(LIMITE_MAXIMO, 200).

init(Req0, Op) ->
  Req = atender(Op, cowboy_req:method(Req0), Req0),
  {ok, Req, Op}.

atender(falla, <<"POST">>, Req0) ->
  Luminaria = cowboy_req:binding(id, Req0),
  case leer_json(Req0) of
    {ok, Datos, Req1} ->
      Prioridad = prioridad(maps:get(<<"prioridad">>, Datos, <<"media">>)),
      Fuente = fuente(maps:get(<<"fuente">>, Datos, <<"ciudadano">>)),
      case {Prioridad, Fuente} of
        {error, _} ->
          responder(400, #{error => <<"prioridad invalida">>}, Req1);
        {_, error} ->
          responder(400, #{error => <<"fuente invalida">>}, Req1);
        _ ->
          {ok, _Pid, Resultado} = p70_registro:reportar(Luminaria, Prioridad, Fuente),
          responder(codigo(Resultado),
                    #{luminaria => Luminaria, resultado => Resultado}, Req1)
      end;
    {error, Req1} ->
      responder(400, #{error => <<"json invalido">>}, Req1)
  end;
atender(mapa, <<"GET">>, Req) ->
  Fallas = [Resumen || {Luminaria, Pid} <- maps:to_list(p70_registro:activas()),
                       {ok, Resumen} <- [resumen(Luminaria, Pid)]],
  responder(200, #{fallas => Fallas}, Req);
atender(falla_id, <<"GET">>, Req) ->
  Luminaria = cowboy_req:binding(id, Req),
  case buscar(Luminaria) of
    {ok, Resumen} ->
      Detalle = Resumen#{reincidencias => p70_registro:reincidencias(Luminaria)},
      responder(200, Detalle, Req);
    error ->
      responder(404, #{error => <<"falla no encontrada">>}, Req)
  end;
atender(falla_id, <<"PATCH">>, Req0) ->
  Luminaria = cowboy_req:binding(id, Req0),
  case p70_registro:buscar(Luminaria) of
    error ->
      responder(404, #{error => <<"falla no encontrada">>}, Req0);
    {ok, Pid} ->
      case leer_json(Req0) of
        {ok, Datos, Req1} -> accion(Pid, Datos, Req1);
        {error, Req1} -> responder(400, #{error => <<"json invalido">>}, Req1)
      end
  end;
atender(bitacora, <<"GET">>, Req) ->
  Limite = limite(cowboy_req:parse_qs(Req)),
  responder(200, #{eventos => p70_bitacora:ultimos(Limite)}, Req);
atender(_Op, _Metodo, Req) ->
  responder(405, #{error => <<"metodo no permitido">>}, Req).

accion(Pid, Datos, Req) ->
  case {maps:get(<<"accion">>, Datos, undefined), maps:find(<<"cuadrilla">>, Datos)} of
    {<<"asignar">>, {ok, Cuadrilla}} ->
      resultado(aplicar(fun() -> p70_falla:asignar(Pid, Cuadrilla) end), Req);
    {<<"reparar">>, _} ->
      resultado(aplicar(fun() -> p70_falla:reparar(Pid) end), Req);
    _ ->
      responder(400, #{error => <<"accion invalida o faltan datos">>}, Req)
  end.

%% La falla pudo morir entre buscarla y llamarla.
aplicar(Fun) ->
  try Fun()
  catch exit:_ -> {error, falla_no_disponible}
  end.

resultado(ok, Req) ->
  responder(200, #{ok => true}, Req);
resultado({error, Razon}, Req) ->
  Texto = iolist_to_binary(io_lib:format("~p", [Razon])),
  responder(409, #{error => Texto}, Req).

buscar(Luminaria) ->
  case p70_registro:buscar(Luminaria) of
    {ok, Pid} -> resumen(Luminaria, Pid);
    error -> error
  end.

%% Campos siempre presentes + los opcionales que ya existan (asignada_a, reparada_en).
resumen(Luminaria, Pid) ->
  try p70_falla:estado(Pid) of
    {Estado, Datos} ->
      Base = #{luminaria => Luminaria,
               estado => Estado,
               prioridad => maps:get(prioridad, Datos),
               reportes => maps:get(reportes, Datos),
               fuentes => contar_fuentes(maps:get(fuentes, Datos)),
               reportada_en => maps:get(reportada_en, Datos)},
      {ok, maps:merge(Base, maps:with([asignada_a, reparada_en], Datos))}
  catch
    exit:_ -> error
  end.

%% [ciudadano, telemetria, ciudadano] -> #{<<"ciudadano">> => 2, <<"telemetria">> => 1}
contar_fuentes(Fuentes) ->
  lists:foldl(fun(F, Acc) ->
                Clave = p70_falla:fuente_tipo(F),
                Acc#{Clave => maps:get(Clave, Acc, 0) + 1}
              end, #{}, Fuentes).

leer_json(Req0) ->
  {ok, Cuerpo, Req1} = cowboy_req:read_body(Req0),
  case Cuerpo of
    <<>> ->
      {ok, #{}, Req1};
    _ ->
      try json:decode(Cuerpo) of
        Mapa when is_map(Mapa) -> {ok, Mapa, Req1};
        _ -> {error, Req1}
      catch
        error:_ -> {error, Req1}
      end
  end.

limite(Qs) ->
  case lists:keyfind(<<"limite">>, 1, Qs) of
    {_, Valor} ->
      try binary_to_integer(Valor) of
        N when N >= 1, N =< ?LIMITE_MAXIMO -> N;
        _ -> ?LIMITE_DEFECTO
      catch
        error:_ -> ?LIMITE_DEFECTO
      end;
    false ->
      ?LIMITE_DEFECTO
  end.

%% Nunca se convierte texto del cliente a atomo (los atomos no se recolectan).
prioridad(<<"alta">>) -> alta;
prioridad(<<"media">>) -> media;
prioridad(<<"baja">>) -> baja;
prioridad(_) -> error.

fuente(<<"ciudadano">>) -> ciudadano;
fuente(<<"telemetria">>) -> telemetria;
fuente(_) -> error.

codigo(agrupada) -> 200;
codigo(_) -> 201.

responder(Codigo, Mapa, Req) ->
  cowboy_req:reply(Codigo, #{<<"content-type">> => <<"application/json">>},
                   json:encode(Mapa), Req).
