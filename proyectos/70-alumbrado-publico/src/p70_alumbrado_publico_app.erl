-module(p70_alumbrado_publico_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  Puerto = application:get_env(p70_alumbrado_publico, http_port, 8080),
  {ok, Sup} = p70_alumbrado_publico_sup:start_link(),
  {ok, _} = p70_http:start(Puerto),
  {ok, Sup}.

stop(_State) ->
  _ = p70_http:stop(),
  ok.
