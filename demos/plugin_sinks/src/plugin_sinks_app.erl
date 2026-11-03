-module(plugin_sinks_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    case plugin_sinks_sup:start_link() of
        {ok, Sup} ->
            Sinks = application:get_env(plugin_sinks, sinks, []),
            lists:foreach(fun({Mod, Opts}) -> {ok, _} = plugin_sinks:add_sink(Mod, Opts) end,
                          Sinks),
            {ok, Sup};
        Error ->
            Error
    end.

stop(_State) ->
    ok.
