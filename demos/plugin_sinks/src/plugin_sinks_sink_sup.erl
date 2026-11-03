-module(plugin_sinks_sink_sup).
-behaviour(supervisor).

-export([start_link/0, start_sink/2, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_sink(Mod, Opts) ->
    supervisor:start_child(?MODULE, [Mod, Opts]).

%% Cada salida es un proceso aislado: si una falla, solo se reinicia esa.
%% transient: se reinicia si muere por error, pero no al quitarla a proposito.
init([]) ->
    SupFlags = #{strategy => simple_one_for_one, intensity => 10, period => 5},
    Child = #{id => sink, start => {plugin_sinks_worker, start_link, []},
              restart => transient},
    {ok, {SupFlags, [Child]}}.
