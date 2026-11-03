-module(hot_upgrade_tests).
-include_lib("eunit/include/eunit.hrl").

upgrade_keeps_pid_and_state_test_() ->
    {setup,
     fun() ->
         ok = application:load(hot_upgrade),
         ok = application:set_env(hot_upgrade, tick_ms, 3600000),
         {ok, _} = application:ensure_all_started(hot_upgrade)
     end,
     fun(_) -> application:stop(hot_upgrade) end,
     fun() ->
         ?assertEqual(1, hot_upgrade:version()),
         ?assertEqual(1, hot_upgrade_counter:bump()),
         ?assertEqual(2, hot_upgrade_counter:bump()),
         Pid = whereis(hot_upgrade_counter),
         ?assertMatch({ok, #{from := 1, to := 2}}, hot_upgrade:upgrade()),
         ?assertEqual(Pid, whereis(hot_upgrade_counter)),
         ?assertEqual(2, hot_upgrade_counter:get()),
         ?assertEqual(7, hot_upgrade_counter:bump())
     end}.
