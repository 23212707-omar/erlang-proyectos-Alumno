%% Registro de fallas activas: garantiza UNA sola falla abierta por luminaria.
%% Resultado de reportar/3:
%%   nueva        -> no habia falla abierta; se abrio una.
%%   agrupada     -> ya habia una abierta; el reporte se sumo a ella (duplicado).
%%   reincidencia -> la anterior ya estaba reparada; se abrio una nueva y se
%%                   cuenta como reincidencia de esa luminaria. La nueva falla
%%                   sube un nivel de prioridad (baja -> media -> alta).
-module(p70_registro).
-behaviour(gen_server).

-export([start_link/0, reportar/3, reincidencias/1, activas/0, buscar/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

reportar(Luminaria, Prioridad, Fuente) ->
  gen_server:call(?MODULE, {reportar, Luminaria, Prioridad, Fuente}).

reincidencias(Luminaria) ->
  gen_server:call(?MODULE, {reincidencias, Luminaria}).

%% Mapa Luminaria => Pid de la falla vigente (incluye la ultima ya reparada hasta
%% que llegue otro reporte de esa luminaria).
activas() ->
  gen_server:call(?MODULE, activas).

buscar(Luminaria) ->
  gen_server:call(?MODULE, {buscar, Luminaria}).

%% activas: Luminaria => Pid de su falla vigente.
%% reincidencias: Luminaria => cuantas veces se reabrio tras una reparacion.
init([]) ->
  {ok, #{activas => #{}, reincidencias => #{}}}.

handle_call({reportar, Luminaria, Prioridad, Fuente}, _From,
            #{activas := Activas} = State) ->
  case maps:find(Luminaria, Activas) of
    error -> abrir(Luminaria, Prioridad, Fuente, nueva, State);
    {ok, Pid} -> agrupar(Pid, Luminaria, Prioridad, Fuente, State)
  end;
handle_call({reincidencias, Luminaria}, _From, #{reincidencias := R} = State) ->
  {reply, maps:get(Luminaria, R, 0), State};
handle_call(activas, _From, #{activas := Activas} = State) ->
  {reply, Activas, State};
handle_call({buscar, Luminaria}, _From, #{activas := Activas} = State) ->
  {reply, maps:find(Luminaria, Activas), State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

%% Si una falla muere, se olvida; el siguiente reporte abrira una nueva.
handle_info({'DOWN', _Ref, process, Pid, _Razon}, #{activas := Activas} = State) ->
  Vigentes = maps:filter(fun(_Luminaria, P) -> P =/= Pid end, Activas),
  {noreply, State#{activas := Vigentes}};
handle_info(_Info, State) ->
  {noreply, State}.

%% --- Internas ---

agrupar(Pid, Luminaria, Prioridad, Fuente, State) ->
  try p70_falla:reportar(Pid, Fuente) of
    ok ->
      anotar(agrupada, Luminaria, Prioridad, Fuente),
      {reply, {ok, Pid, agrupada}, State};
    {error, falla_cerrada} ->
      Anterior = prioridad_de(Pid),
      abrir(Luminaria, subir(mas_urgente(Anterior, Prioridad)), Fuente, reincidencia,
            sumar_reincidencia(Luminaria, State))
  catch
    %% La falla murio justo antes de que llegara el aviso 'DOWN'.
    exit:_ ->
      abrir(Luminaria, Prioridad, Fuente, nueva, State)
  end.

abrir(Luminaria, Prioridad, Fuente, Resultado, #{activas := Activas} = State) ->
  {ok, Pid} = p70_falla_sup:abrir(Luminaria, Prioridad, Fuente),
  erlang:monitor(process, Pid),
  anotar(Resultado, Luminaria, Prioridad, Fuente),
  {reply, {ok, Pid, Resultado}, State#{activas := Activas#{Luminaria => Pid}}}.

anotar(Tipo, Luminaria, Prioridad, Fuente) ->
  p70_bitacora:registrar(Tipo, Luminaria,
                         #{prioridad => Prioridad, fuente => p70_falla:fuente_tipo(Fuente)}).

sumar_reincidencia(Luminaria, #{reincidencias := R} = State) ->
  State#{reincidencias := R#{Luminaria => maps:get(Luminaria, R, 0) + 1}}.

%% La prioridad de la falla anterior queda visible en su mapa de datos aunque
%% este reparada; de ahi parte la escalada de la nueva falla.
prioridad_de(Pid) ->
  {_, Datos} = p70_falla:estado(Pid),
  maps:get(prioridad, Datos).

mas_urgente(A, B) ->
  Orden = #{baja => 1, media => 2, alta => 3},
  case {maps:get(A, Orden), maps:get(B, Orden)} of
    {Rango_A, Rango_B} when Rango_A >= Rango_B -> A;
    _ -> B
  end.

%% Una luminaria que reincide es mas urgente que la reportada por primera vez.
subir(baja) -> media;
subir(media) -> alta;
subir(alta) -> alta.
