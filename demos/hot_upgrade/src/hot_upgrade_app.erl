-module(hot_upgrade_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    hot_upgrade_sup:start_link().

stop(_State) ->
    ok.
