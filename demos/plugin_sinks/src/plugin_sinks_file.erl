%% Una linea por lectura en un archivo; el único sink que implementa terminate/2.
-module(plugin_sinks_file).
-behaviour(plugin_sinks_sink).

-export([init/1, write/2, terminate/2]).

init(#{path := Path}) ->
    case file:open(Path, [append, binary]) of
        {ok, Fd} -> {ok, Fd};
        {error, Reason} -> {error, {cannot_open, Path, Reason}}
    end;
init(_Opts) ->
    {error, missing_path}.

write(#{sensor := Sensor, ts := Ts, value := Value}, Fd) ->
    ok = file:write(Fd, io_lib:format("~p,~p,~p~n", [Ts, Sensor, Value])),
    {ok, Fd}.

terminate(_Reason, Fd) ->
    _ = file:close(Fd),
    ok.
