-module(let_it_crash_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    let_it_crash_sup:start_link().

stop(_State) ->
    ok.
