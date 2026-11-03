-module(let_it_crash_sensors_sup).
-behaviour(supervisor).

-export([start_link/0, init/1, sensors/0]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

sensors() ->
    [sensor_a, sensor_b, sensor_c].

%% one_for_one: los sensores son independientes; si uno falla, los demas ni se enteran.
init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 5, period => 10},
    Children = [#{id => Name, start => {let_it_crash_sensor, start_link, [Name]}}
                || Name <- sensors()],
    {ok, {SupFlags, Children}}.
