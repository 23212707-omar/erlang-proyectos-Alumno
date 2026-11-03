-module(let_it_crash_tests).
-include_lib("eunit/include/eunit.hrl").

setup() ->
    {ok, _} = application:ensure_all_started(let_it_crash),
    ok.

cleanup(_) ->
    application:stop(let_it_crash).

restart_test_() ->
    {setup, fun setup/0, fun cleanup/1, [
        fun sensor_crash_only_restarts_itself/0,
        fun store_crash_restarts_dependents/0
    ]}.

wait_restarted(Name, OldPid) ->
    wait_restarted(Name, OldPid, 50).

wait_restarted(_Name, _OldPid, 0) -> error(not_restarted);
wait_restarted(Name, OldPid, N) ->
    case whereis(Name) of
        Pid when is_pid(Pid), Pid =/= OldPid -> Pid;
        _ -> timer:sleep(20), wait_restarted(Name, OldPid, N - 1)
    end.

sensor_crash_only_restarts_itself() ->
    Before = let_it_crash:snapshot(),
    exit(maps:get(sensor_a, Before), kill),
    wait_restarted(sensor_a, maps:get(sensor_a, Before)),
    ?assertEqual([sensor_a], let_it_crash:changed(Before, let_it_crash:snapshot())).

store_crash_restarts_dependents() ->
    Before = let_it_crash:snapshot(),
    exit(maps:get(let_it_crash_store, Before), kill),
    wait_restarted(sensor_c, maps:get(sensor_c, Before)),
    Changed = let_it_crash:changed(Before, let_it_crash:snapshot()),
    ?assertEqual(lists:sort([let_it_crash_store, let_it_crash_agg, let_it_crash_sensors_sup,
                             sensor_a, sensor_b, sensor_c]), Changed).
