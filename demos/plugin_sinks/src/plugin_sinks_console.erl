-module(plugin_sinks_console).
-behaviour(plugin_sinks_sink).

-export([init/1, write/2]).

init(_Opts) ->
    {ok, #{}}.

write(#{sensor := Sensor, value := Value}, State) ->
    io:format("[console] ~p = ~p~n", [Sensor, Value]),
    {ok, State}.
