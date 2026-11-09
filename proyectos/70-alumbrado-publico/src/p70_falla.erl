%% Una falla de alumbrado = un proceso gen_statem.
%% Ciclo de vida: reportada -> asignada -> reparada.
%% Por que un proceso por falla: cada falla tiene su propio estado y su propio
%% ritmo; si una se cae, las demas siguen atendiendose (aislamiento de fallos).
-module(p70_falla).
-behaviour(gen_statem).

-export([start_link/3, reportar/2, asignar/2, reparar/1, estado/1, fuente_tipo/1]).
-export([init/1, callback_mode/0, reportada/3, asignada/3, reparada/3]).

%% Luminaria: id del poste. Prioridad: alta | media | baja. Fuente: quien reporta
%% por primera vez (ciudadano | telemetria | ...).
start_link(Luminaria, Prioridad, Fuente) ->
  gen_statem:start_link(?MODULE, {Luminaria, Prioridad, Fuente}, []).

%% Otro reporte del mismo poste: se agrupa en esta falla en lugar de crear otra.
reportar(Pid, Fuente) -> gen_statem:call(Pid, {reportar, Fuente}).

asignar(Pid, Cuadrilla) -> gen_statem:call(Pid, {asignar, Cuadrilla}).

reparar(Pid) -> gen_statem:call(Pid, reparar).

estado(Pid) -> gen_statem:call(Pid, estado).

%% Normaliza una fuente a un binario ({ciudadano, 3} y ciudadano -> <<"ciudadano">>).
fuente_tipo(Fuente) when is_binary(Fuente) -> Fuente;
fuente_tipo(Fuente) when is_atom(Fuente) -> atom_to_binary(Fuente, utf8);
fuente_tipo({Tipo, _}) -> fuente_tipo(Tipo);
fuente_tipo(_) -> <<"otra">>.

callback_mode() -> state_functions.

%% Estado como mapa para poder agregar campos sin romper los callbacks.
init({Luminaria, Prioridad, Fuente}) ->
  Data = #{luminaria => Luminaria,
           prioridad => Prioridad,
           reportes => 1,
           fuentes => [Fuente],
           reportada_en => erlang:system_time(second)},
  logger:info("falla abierta", #{luminaria => Luminaria, prioridad => Prioridad}),
  {ok, reportada, Data}.

%% --- Estado: reportada ---
reportada({call, From}, {reportar, Fuente}, Data) ->
  {keep_state, sumar_reporte(Fuente, Data), [{reply, From, ok}]};
reportada({call, From}, {asignar, Cuadrilla}, Data) ->
  p70_bitacora:registrar(asignada, maps:get(luminaria, Data), #{cuadrilla => Cuadrilla}),
  {next_state, asignada, Data#{asignada_a => Cuadrilla}, [{reply, From, ok}]};
reportada(Tipo, Evento, Data) ->
  comun(Tipo, Evento, reportada, Data).

%% --- Estado: asignada ---
asignada({call, From}, {reportar, Fuente}, Data) ->
  {keep_state, sumar_reporte(Fuente, Data), [{reply, From, ok}]};
asignada({call, From}, reparar, Data) ->
  Nueva = Data#{reparada_en => erlang:system_time(second)},
  p70_bitacora:registrar(reparada, maps:get(luminaria, Data),
                         #{reportes => maps:get(reportes, Data)}),
  {next_state, reparada, Nueva, [{reply, From, ok}]};
asignada(Tipo, Evento, Data) ->
  comun(Tipo, Evento, asignada, Data).

%% --- Estado: reparada ---
%% Un reporte despues de reparar NO reabre la falla: devolvemos error y quien
%% llama decide abrir una nueva (asi se puede contar la reincidencia).
reparada({call, From}, {reportar, _Fuente}, _Data) ->
  {keep_state_and_data, [{reply, From, {error, falla_cerrada}}]};
reparada(Tipo, Evento, Data) ->
  comun(Tipo, Evento, reparada, Data).

%% --- Eventos comunes a todos los estados ---
comun({call, From}, estado, Estado, Data) ->
  {keep_state_and_data, [{reply, From, {Estado, Data}}]};
comun({call, From}, Evento, Estado, _Data) ->
  {keep_state_and_data, [{reply, From, {error, {evento_invalido, Evento, Estado}}}]};
comun(_Tipo, _Evento, _Estado, _Data) ->
  keep_state_and_data.

sumar_reporte(Fuente, #{reportes := N, fuentes := Fuentes} = Data) ->
  Data#{reportes := N + 1, fuentes := [Fuente | Fuentes]}.
