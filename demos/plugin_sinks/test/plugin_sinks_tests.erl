-module(plugin_sinks_tests).
-include_lib("eunit/include/eunit.hrl").

sinks_test_() ->
    {setup,
     fun() ->
         ok = application:load(plugin_sinks),
         ok = application:set_env(plugin_sinks, interval_ms, 20),
         ok = application:set_env(plugin_sinks, sinks, [{plugin_sinks_memory, #{max => 3}}]),
         {ok, _} = application:ensure_all_started(plugin_sinks)
     end,
     fun(_) -> application:stop(plugin_sinks) end,
     [fun memory_keeps_last_n/0,
      fun rejects_non_sinks/0,
      fun add_and_remove_at_runtime/0,
      fun flaky_sink_is_isolated/0]}.

wait_until(Fun) -> wait_until(Fun, 100).
wait_until(_Fun, 0) -> error(timeout);
wait_until(Fun, N) ->
    case Fun() of
        true -> ok;
        false -> timer:sleep(20), wait_until(Fun, N - 1)
    end.

memory_keeps_last_n() ->
    [{Pid, plugin_sinks_memory}] = plugin_sinks:sinks(),
    ok = wait_until(fun() -> length(maps:get(readings, plugin_sinks:dump(Pid))) =:= 3 end).

rejects_non_sinks() ->
    ?assertEqual({error, {not_a_sink, lists}}, plugin_sinks:add_sink(lists, #{})).

add_and_remove_at_runtime() ->
    Before = length(plugin_sinks:sinks()),
    {ok, Pid} = plugin_sinks:add_sink(plugin_sinks_console, #{}),
    ?assertEqual(Before + 1, length(plugin_sinks:sinks())),
    ok = plugin_sinks:remove_sink(Pid),
    ?assertEqual(Before, length(plugin_sinks:sinks())).

flaky_sink_is_isolated() ->
    [{Mem, plugin_sinks_memory}] = plugin_sinks:sinks(),
    {ok, Flaky} = plugin_sinks:add_sink(plugin_sinks_flaky, #{}),
    Ref = monitor(process, Flaky),
    receive {'DOWN', Ref, process, Flaky, _} -> ok after 2000 -> error(flaky_did_not_crash) end,
    ?assert(is_process_alive(Mem)),
    %% el supervisor lo reinicia (transient + muerte anormal)
    ok = wait_until(fun() -> length(plugin_sinks:sinks()) =:= 2 end).
