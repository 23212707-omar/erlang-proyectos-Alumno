-module(plugin_sinks_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% rest_for_one: sink_sup y sensor usan el grupo de pg, asi que dependen de el.
init([]) ->
    SupFlags = #{strategy => rest_for_one, intensity => 5, period => 10},
    Children = [
        #{id => pg, start => {pg, start_link, []}},
        #{id => plugin_sinks_sink_sup,
          start => {plugin_sinks_sink_sup, start_link, []},
          type => supervisor},
        #{id => plugin_sinks_sensor, start => {plugin_sinks_sensor, start_link, []}}
    ],
    {ok, {SupFlags, Children}}.
