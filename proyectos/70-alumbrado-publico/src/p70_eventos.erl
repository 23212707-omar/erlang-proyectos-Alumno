%% Canal de eventos en tiempo real. Quien quiera enterarse de cada cambio (hoy, las
%% conexiones WebSocket de la interfaz) se suscribe con su pid; la bitacora publica
%% cada evento que registra y el canal se lo reenvia a todos como {evento, Evento}.
%% Se monitorea a cada suscriptor: si muere, se da de baja solo.
%% publicar/1 es un cast: nunca bloquea a quien reporta, y no falla aunque el canal
%% este caido (la interfaz tiene su refresco periodico como respaldo).
-module(p70_eventos).
-behaviour(gen_server).

-export([start_link/0, suscribir/1, publicar/1, suscriptores/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Idempotente: suscribir dos veces al mismo pid no duplica los envios.
suscribir(Pid) ->
  gen_server:call(?MODULE, {suscribir, Pid}).

publicar(Evento) ->
  gen_server:cast(?MODULE, {publicar, Evento}).

suscriptores() ->
  gen_server:call(?MODULE, suscriptores).

%% Estado: Pid => referencia del monitor.
init([]) ->
  {ok, #{}}.

handle_call({suscribir, Pid}, _From, Suscriptores) ->
  case maps:is_key(Pid, Suscriptores) of
    true -> {reply, ok, Suscriptores};
    false -> {reply, ok, Suscriptores#{Pid => erlang:monitor(process, Pid)}}
  end;
handle_call(suscriptores, _From, Suscriptores) ->
  {reply, lists:sort(maps:keys(Suscriptores)), Suscriptores}.

handle_cast({publicar, Evento}, Suscriptores) ->
  lists:foreach(fun(Pid) -> Pid ! {evento, Evento} end, maps:keys(Suscriptores)),
  {noreply, Suscriptores};
handle_cast(_Msg, Suscriptores) ->
  {noreply, Suscriptores}.

handle_info({'DOWN', _Ref, process, Pid, _Razon}, Suscriptores) ->
  {noreply, maps:remove(Pid, Suscriptores)};
handle_info(_Info, Suscriptores) ->
  {noreply, Suscriptores}.
