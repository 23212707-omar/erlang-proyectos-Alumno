%% Bitacora de eventos: guarda los ultimos ?MAX eventos (el mas reciente primero).
%% Tipos: nueva | agrupada | reincidencia | asignada | reparada.
%% registrar/3 es un cast: nunca bloquea al que reporta y no falla aunque la
%% bitacora no este arriba. Es memoria volatil; la persistencia queda pendiente.
-module(p70_bitacora).
-behaviour(gen_server).

-export([start_link/0, registrar/3, ultimos/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(MAX, 200).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

registrar(Tipo, Luminaria, Detalle) ->
  gen_server:cast(?MODULE, {registrar, Tipo, Luminaria, Detalle}).

ultimos(N) ->
  gen_server:call(?MODULE, {ultimos, N}).

init([]) ->
  {ok, #{siguiente => 1, eventos => []}}.

handle_call({ultimos, N}, _From, #{eventos := Eventos} = State) ->
  {reply, lists:sublist(Eventos, N), State}.

handle_cast({registrar, Tipo, Luminaria, Detalle},
            #{siguiente := Id, eventos := Eventos} = State) ->
  Evento = #{id => Id,
             tipo => Tipo,
             luminaria => Luminaria,
             detalle => Detalle,
             hora => erlang:system_time(second)},
  {noreply, State#{siguiente := Id + 1,
                   eventos := lists:sublist([Evento | Eventos], ?MAX)}};
handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.
