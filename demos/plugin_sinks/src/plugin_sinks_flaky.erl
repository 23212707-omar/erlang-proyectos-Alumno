%% Salida defectuosa a proposito: falla cada 3 escrituras para mostrar que el
%% error queda contenido en su proceso y las demas salidas siguen funcionando.
-module(plugin_sinks_flaky).
-behaviour(plugin_sinks_sink).

-export([init/1, write/2]).

init(_Opts) ->
    {ok, 0}.

write(_Reading, N) when N rem 3 =:= 2 ->
    error(sink_defectuoso);
write(_Reading, N) ->
    {ok, N + 1}.
