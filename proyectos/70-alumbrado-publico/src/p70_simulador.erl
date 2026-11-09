%% Simulador de reportes y de cuadrillas, para la demo. Todo es SIMULADO.
%%
%% Modo continuo (iniciar/0 y detener/0): genera 80 reportes por "dia simulado" (un dia
%% dura un minuto, asi que sale un reporte cada 750 ms) sobre luminarias elegidas al
%% azar del catalogo. En cada paso tambien despacha y repara: 4 cuadrillas atienden
%% hasta 3 fallas a la vez cada una, empezando por la de mayor prioridad.
%%
%% Escenarios puntuales para la demo:
%%   escenario_poste(Luminaria)      15 reportes del mismo poste -> una sola falla.
%%   escenario_circuito(Circuito)    todas las luminarias de un circuito fallan a la vez.
%%
%% tick/0 ejecuta un paso sincrono (lo usan las pruebas, sin esperar al reloj).
-module(p70_simulador).
-behaviour(gen_server).

-export([start_link/0, iniciar/0, detener/0, estado/0, tick/0,
         escenario_poste/1, escenario_circuito/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TOTAL, 5000).
-define(REPORTES_POR_DIA, 80).
-define(DIA_MS, 60000).
-define(CAPACIDAD, 3).
-define(CUADRILLAS, [<<"cuadrilla_1">>, <<"cuadrilla_2">>, <<"cuadrilla_3">>, <<"cuadrilla_4">>]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

iniciar() -> gen_server:call(?MODULE, iniciar).
detener() -> gen_server:call(?MODULE, detener).
estado() -> gen_server:call(?MODULE, estado).
tick() -> gen_server:call(?MODULE, tick).

%% {ok, Resultado} | {error, luminaria_desconocida}
escenario_poste(Luminaria) -> gen_server:call(?MODULE, {poste, Luminaria}, 30000).

%% {ok, Resultado} | {error, circuito_desconocido}
escenario_circuito(Circuito) -> gen_server:call(?MODULE, {circuito, Circuito}, 30000).

%% --- gen_server ---

init([]) ->
  {ok, #{activo => false, timer => undefined, ticks => 0, reportes => 0,
         nuevas => 0, agrupadas => 0, reincidencias => 0, asignadas => 0, reparadas => 0}}.

handle_call(iniciar, _From, #{activo := true} = S) ->
  {reply, vista(S), S};
handle_call(iniciar, _From, S) ->
  S1 = S#{activo := true, timer := programar()},
  logger:info("simulador iniciado"),
  {reply, vista(S1), S1};
handle_call(detener, _From, #{timer := Timer} = S) ->
  cancelar(Timer),
  S1 = S#{activo := false, timer := undefined},
  {reply, vista(S1), S1};
handle_call(estado, _From, S) ->
  {reply, vista(S), S};
handle_call(tick, _From, S) ->
  S1 = paso(S),
  {reply, vista(S1), S1};
handle_call({poste, Luminaria}, _From, S) ->
  case p70_catalogo:buscar(Luminaria) of
    error ->
      {reply, {error, luminaria_desconocida}, S};
    {ok, _} ->
      Resultados = [reportar(Luminaria, alta, fuente_de(N)) || N <- lists:seq(1, 15)],
      Resumen = maps:merge(#{luminaria => Luminaria, enviados => 15}, tabular(Resultados)),
      {reply, {ok, Resumen}, S}
  end;
handle_call({circuito, Circuito}, _From, S) ->
  case p70_catalogo:luminarias_de_circuito(Circuito) of
    [] ->
      {reply, {error, circuito_desconocido}, S};
    Ids ->
      Resultados = [reportar(Id, alta, telemetria) || Id <- Ids],
      Resumen = maps:merge(#{circuito => Circuito, luminarias => length(Ids)}, tabular(Resultados)),
      {reply, {ok, Resumen}, S}
  end.

handle_cast(_Msg, S) ->
  {noreply, S}.

handle_info(tick, #{activo := true} = S) ->
  S1 = paso(S),
  {noreply, S1#{timer := programar()}};
handle_info(_Info, S) ->
  %% Un tick que llega despues de detener se ignora.
  {noreply, S}.

%% --- Un paso: un reporte, un despacho y (casi siempre) una reparacion ---

paso(S0) ->
  Resultado = reportar_aleatoria(),
  Fallas = fallas(),
  Despacho = despachar(Fallas),
  Reparacion = reparar_una(Fallas),
  S1 = sumar(contador(Resultado), sumar(reportes, S0)),
  S2 = case Despacho of
         asignada -> sumar(asignadas, S1);
         ninguna -> S1
       end,
  S3 = case Reparacion of
         reparada -> sumar(reparadas, S2);
         ninguna -> S2
       end,
  sumar(ticks, S3).

reportar_aleatoria() ->
  Id = id(rand:uniform(?TOTAL)),
  Prioridad = case p70_catalogo:buscar(Id) of
                {ok, #{lugar := Lugar}} -> prioridad_de(Lugar);
                error -> media
              end,
  Fuente = case rand:uniform() < 0.3 of
             true -> telemetria;
             false -> ciudadano
           end,
  reportar(Id, Prioridad, Fuente).

reportar(Id, Prioridad, Fuente) ->
  {ok, _Pid, Resultado} = p70_registro:reportar(Id, Prioridad, Fuente),
  Resultado.

%% Fallas vigentes con su estado: [{Luminaria, Pid, Estado, Datos}].
fallas() ->
  lists:flatmap(fun({Luminaria, Pid}) ->
                  try p70_falla:estado(Pid) of
                    {Estado, Datos} -> [{Luminaria, Pid, Estado, Datos}]
                  catch
                    exit:_ -> []
                  end
                end, maps:to_list(p70_registro:activas())).

%% Asigna la falla pendiente mas urgente a la cuadrilla menos cargada, si tiene lugar.
despachar(Fallas) ->
  Pendientes = [F || {_, _, reportada, _} = F <- Fallas],
  Urgentes = lists:sort(fun({_, _, _, A}, {_, _, _, B}) -> orden(A) =< orden(B) end, Pendientes),
  case {Urgentes, cuadrilla_libre(cargas(Fallas))} of
    {[{_, Pid, _, _} | _], {ok, Cuadrilla}} ->
      case aplicar(fun() -> p70_falla:asignar(Pid, Cuadrilla) end) of
        ok -> asignada;
        _ -> ninguna
      end;
    _ ->
      ninguna
  end.

%% Repara la falla asignada mas antigua (3 de cada 4 pasos).
reparar_una(Fallas) ->
  case rand:uniform() < 0.75 of
    false ->
      ninguna;
    true ->
      Asignadas = [F || {_, _, asignada, _} = F <- Fallas],
      Antiguas = lists:sort(fun({_, _, _, A}, {_, _, _, B}) ->
                              maps:get(reportada_en, A) =< maps:get(reportada_en, B)
                            end, Asignadas),
      case Antiguas of
        [{_, Pid, _, _} | _] ->
          case aplicar(fun() -> p70_falla:reparar(Pid) end) of
            ok -> reparada;
            _ -> ninguna
          end;
        [] ->
          ninguna
      end
  end.

%% Cuantas fallas asignadas tiene cada cuadrilla.
cargas(Fallas) ->
  lists:foldl(fun({_, _, asignada, Datos}, Acc) ->
                    Cuadrilla = maps:get(asignada_a, Datos),
                    Acc#{Cuadrilla => maps:get(Cuadrilla, Acc, 0) + 1};
                 (_, Acc) ->
                    Acc
              end, #{}, Fallas).

cuadrilla_libre(Cargas) ->
  {Menor, Cuadrilla} = lists:min([{maps:get(C, Cargas, 0), C} || C <- ?CUADRILLAS]),
  case Menor < ?CAPACIDAD of
    true -> {ok, Cuadrilla};
    false -> ninguna
  end.

%% La falla pudo morir entre listarla y llamarla.
aplicar(Fun) ->
  try Fun()
  catch exit:_ -> {error, falla_no_disponible}
  end.

%% --- Utilidades ---

orden(Datos) ->
  {rango(maps:get(prioridad, Datos)), -maps:get(reportes, Datos), maps:get(reportada_en, Datos)}.

rango(alta) -> 0;
rango(media) -> 1;
rango(baja) -> 2.

prioridad_de(avenida) -> alta;
prioridad_de(cruce_escolar) -> alta;
prioridad_de(hospital) -> alta;
prioridad_de(calle) -> media;
prioridad_de(andador) -> baja;
prioridad_de(_) -> media.

fuente_de(N) when N rem 3 =:= 0 -> telemetria;
fuente_de(_) -> ciudadano.

id(N) ->
  iolist_to_binary(io_lib:format("L-~4..0w", [N])).

contador(nueva) -> nuevas;
contador(agrupada) -> agrupadas;
contador(reincidencia) -> reincidencias.

sumar(Clave, S) ->
  S#{Clave := maps:get(Clave, S) + 1}.

tabular(Resultados) ->
  #{nuevas => length([x || nueva <- Resultados]),
    agrupadas => length([x || agrupada <- Resultados]),
    reincidencias => length([x || reincidencia <- Resultados])}.

vista(S) ->
  maps:merge(maps:with([activo, ticks, reportes, nuevas, agrupadas, reincidencias,
                        asignadas, reparadas], S),
             #{dia => maps:get(ticks, S) div ?REPORTES_POR_DIA + 1,
               reportes_por_dia => ?REPORTES_POR_DIA,
               dia_ms => ?DIA_MS}).

programar() ->
  erlang:send_after(?DIA_MS div ?REPORTES_POR_DIA, self(), tick).

cancelar(undefined) -> ok;
cancelar(Timer) -> _ = erlang:cancel_timer(Timer), ok.
