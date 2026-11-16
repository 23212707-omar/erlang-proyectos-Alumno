%% WebSocket de la interfaz (GET /ws). Al conectarse manda {"tipo":"conectado"} y se
%% suscribe a p70_eventos; despues manda {"tipo":"evento","evento":{...}} por cada
%% cambio (mismo formato que GET /api/bitacora). La interfaz usa estos avisos para
%% refrescar el mapa al instante y conserva su refresco periodico como respaldo.
%%
%% Cada ?LATIDO_MS se manda un ping (el navegador contesta solo y eso evita que cowboy
%% cierre la conexion por inactividad) y se repite la suscripcion: si p70_eventos se
%% reinicio, la conexion vuelve a quedar suscrita sin que la interfaz haga nada.
-module(p70_ws_h).
-behaviour(cowboy_websocket).

-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2, terminate/3]).

-define(LATIDO_MS, 10000).

init(Req, _Opciones) ->
  {cowboy_websocket, Req, #{}, #{idle_timeout => 60000}}.

websocket_init(Estado) ->
  suscribir(),
  erlang:send_after(?LATIDO_MS, self(), latido),
  {[{text, json:encode(#{tipo => conectado})}], Estado}.

%% La interfaz no manda nada; lo que llegue se ignora.
websocket_handle(_Marco, Estado) ->
  {[], Estado}.

websocket_info({evento, Evento}, Estado) ->
  {[{text, json:encode(#{tipo => evento, evento => Evento})}], Estado};
websocket_info(latido, Estado) ->
  suscribir(),
  erlang:send_after(?LATIDO_MS, self(), latido),
  {[ping], Estado};
websocket_info(_Info, Estado) ->
  {[], Estado}.

terminate(_Razon, _Req, _Estado) ->
  ok.

suscribir() ->
  try p70_eventos:suscribir(self())
  catch exit:_ -> ok
  end.
