-module(let_it_crash_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% rest_for_one porque agg y los sensores dependen de la tabla ETS del store:
%% si el store cae, lo que se arranco despues debe reiniciarse con el.
init([]) ->
    SupFlags = #{strategy => rest_for_one, intensity => 5, period => 10},
    Children = [
        #{id => let_it_crash_store, start => {let_it_crash_store, start_link, []}},
        #{id => let_it_crash_agg, start => {let_it_crash_agg, start_link, []}},
        #{id => let_it_crash_sensors_sup,
          start => {let_it_crash_sensors_sup, start_link, []},
          type => supervisor}
    ],
    {ok, {SupFlags, Children}}.
