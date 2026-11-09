-module(p70_api_tests).
-include_lib("eunit/include/eunit.hrl").

%% Cada prueba arranca el arbol, levanta el listener en un puerto libre y al final
%% lo detiene y espera a que el supervisor termine.
api_test_() ->
  {foreach,
   fun() ->
     {ok, _} = application:ensure_all_started(cowboy),
     {ok, _} = application:ensure_all_started(inets),
     {ok, Sup} = p70_alumbrado_publico_sup:start_link(),
     {ok, _} = p70_http:start(0),
     {Sup, ranch:get_port(p70_http)}
   end,
   fun({Sup, _Puerto}) ->
     ok = p70_http:stop(),
     Ref = monitor(process, Sup),
     unlink(Sup),
     exit(Sup, shutdown),
     receive {'DOWN', Ref, process, Sup, _} -> ok end
   end,
   [fun post_crea_falla/1,
    fun quince_posts_una_falla_en_el_mapa/1,
    fun flujo_asignar_y_reparar/1,
    fun falla_inexistente_404/1,
    fun fuente_invalida_400/1,
    fun detalle_con_fuentes/1,
    fun bitacora_registra_eventos/1,
    fun luminaria_desconocida_404/1,
    fun falla_con_ubicacion/1,
    fun resumen_del_catalogo/1,
    fun puntos_y_luminaria_del_catalogo/1,
    fun simulador_por_http/1]}.

post_crea_falla({_Sup, Puerto}) ->
  ?_test(begin
    Respuesta = peticion(post, Puerto, "/api/lamparas/L-0001/falla",
                         "{\"prioridad\":\"alta\"}"),
    ?assertMatch({201, #{<<"resultado">> := <<"nueva">>}}, Respuesta)
  end).

%% Caso del escenario: 15 reportes del mismo poste -> una sola falla en el mapa.
quince_posts_una_falla_en_el_mapa({_Sup, Puerto}) ->
  ?_test(begin
    [{_, _} = peticion(post, Puerto, "/api/lamparas/L-0002/falla", "{}")
     || _ <- lists:seq(1, 15)],
    {200, #{<<"fallas">> := Fallas}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch([#{<<"reportes">> := 15, <<"estado">> := <<"reportada">>}], Fallas)
  end).

flujo_asignar_y_reparar({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0003/falla", "{}"),
    ?assertMatch({200, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"asignar\",\"cuadrilla\":\"cuadrilla_1\"}")),
    ?assertMatch({200, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"reparar\"}")),
    %% Reparar dos veces es una transicion invalida.
    ?assertMatch({409, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"reparar\"}"))
  end).

falla_inexistente_404({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({404, _}, peticion(patch, Puerto, "/api/fallas/NO-EXISTE",
                                    "{\"accion\":\"reparar\"}"))).

fuente_invalida_400({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({400, _}, peticion(post, Puerto, "/api/lamparas/L-0004/falla",
                                    "{\"fuente\":\"otra\"}"))).

%% El detalle cuenta cuantos reportes vienen de cada fuente.
detalle_con_fuentes({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"telemetria\"}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"telemetria\"}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"ciudadano\"}"),
    {200, Detalle} = peticion(get, Puerto, "/api/fallas/L-0005", ""),
    ?assertMatch(#{<<"fuentes">> := #{<<"telemetria">> := 2, <<"ciudadano">> := 1},
                   <<"reportes">> := 3,
                   <<"reincidencias">> := 0}, Detalle),
    ?assert(is_integer(maps:get(<<"reportada_en">>, Detalle)))
  end).

%% La bitacora lista los eventos, el mas reciente primero.
bitacora_registra_eventos({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0006/falla", "{}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0006/falla", "{}"),
    {200, _} = peticion(patch, Puerto, "/api/fallas/L-0006",
      "{\"accion\":\"asignar\",\"cuadrilla\":\"cuadrilla_2\"}"),
    {200, #{<<"eventos">> := Eventos}} = peticion(get, Puerto, "/api/bitacora", ""),
    Tipos = [maps:get(<<"tipo">>, E) || E <- Eventos],
    ?assertEqual([<<"asignada">>, <<"agrupada">>, <<"nueva">>], Tipos)
  end).

%% Reportar una luminaria que no esta en el catalogo es un error.
luminaria_desconocida_404({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/lamparas/L-9999/falla", "{}"))).

%% El mapa de fallas trae la ubicacion que viene del catalogo.
falla_con_ubicacion({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0010/falla", "{}"),
    {200, #{<<"fallas">> := [Falla]}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch(#{<<"luminaria">> := <<"L-0010">>, <<"sector">> := _,
                   <<"direccion">> := _, <<"circuito">> := _}, Falla),
    ?assert(is_float(maps:get(<<"lat">>, Falla))),
    ?assert(is_float(maps:get(<<"lon">>, Falla)))
  end).

resumen_del_catalogo({_Sup, Puerto}) ->
  ?_test(begin
    {200, Resumen} = peticion(get, Puerto, "/api/catalogo/resumen", ""),
    ?assertMatch(#{<<"total">> := 5000, <<"sectores">> := [_ | _]}, Resumen)
  end).

puntos_y_luminaria_del_catalogo({_Sup, Puerto}) ->
  ?_test(begin
    {200, #{<<"puntos">> := Puntos}} = peticion(get, Puerto, "/api/catalogo/puntos", ""),
    ?assertEqual(5000, length(Puntos)),
    ?assertMatch({200, #{<<"id">> := <<"L-0042">>}},
                 peticion(get, Puerto, "/api/catalogo/lamparas/L-0042", "")),
    ?assertMatch({404, _}, peticion(get, Puerto, "/api/catalogo/lamparas/L-9999", ""))
  end).

%% El simulador por HTTP: estado, escenario del poste y del circuito, iniciar y detener.
simulador_por_http({_Sup, Puerto}) ->
  ?_test(begin
    ?assertMatch({200, #{<<"activo">> := false, <<"reportes_por_dia">> := 80}},
                 peticion(get, Puerto, "/api/simulador", "")),
    ?assertMatch({200, #{<<"enviados">> := 15, <<"nuevas">> := 1, <<"agrupadas">> := 14}},
                 peticion(post, Puerto, "/api/simulador/escenarios/poste", "{}")),
    {200, #{<<"fallas">> := Fallas}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch([#{<<"luminaria">> := <<"L-0777">>, <<"reportes">> := 15}], Fallas),
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/simulador/escenarios/poste",
                                    "{\"luminaria\":\"L-9999\"}")),
    ?assertMatch({200, #{<<"luminarias">> := 40, <<"nuevas">> := 40}},
                 peticion(post, Puerto, "/api/simulador/escenarios/circuito", "{}")),
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/simulador/escenarios/circuito",
                                    "{\"circuito\":\"C-XXX-99\"}")),
    ?assertMatch({200, #{<<"activo">> := true}}, peticion(post, Puerto, "/api/simulador/iniciar", "{}")),
    ?assertMatch({200, #{<<"activo">> := false}}, peticion(post, Puerto, "/api/simulador/detener", "{}"))
  end).

peticion(Metodo, Puerto, Ruta, Cuerpo) ->
  Url = "http://127.0.0.1:" ++ integer_to_list(Puerto) ++ Ruta,
  Pedido = case Metodo of
    get -> {Url, []};
    _ -> {Url, [], "application/json", Cuerpo}
  end,
  {ok, {{_, Codigo, _}, _Cabeceras, Resp}} = httpc:request(Metodo, Pedido, [], []),
  {Codigo, json:decode(list_to_binary(Resp))}.
