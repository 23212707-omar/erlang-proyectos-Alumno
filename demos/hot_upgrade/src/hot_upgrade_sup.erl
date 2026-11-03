-module(hot_upgrade_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 3, period => 10},
    Children = [#{id => hot_upgrade_counter,
                  start => {hot_upgrade_counter, start_link, []}}],
    {ok, {SupFlags, Children}}.
