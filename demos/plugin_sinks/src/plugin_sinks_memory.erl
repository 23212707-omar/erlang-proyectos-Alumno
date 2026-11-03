%% Guarda las ultimas `max` lecturas en el estado del proceso (util para pruebas).
-module(plugin_sinks_memory).
-behaviour(plugin_sinks_sink).

-export([init/1, write/2]).

init(Opts) ->
    {ok, #{max => maps:get(max, Opts, 10), readings => []}}.

write(Reading, #{max := Max, readings := Readings} = State) ->
    {ok, State#{readings := lists:sublist([Reading | Readings], Max)}}.
