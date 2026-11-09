-module(p70_alumbrado_publico_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p70_alumbrado_publico_sup:start_link(), Pid end,
   fun(Pid) ->
     Ref = monitor(process, Pid),
     unlink(Pid),
     exit(Pid, shutdown),
     receive {'DOWN', Ref, process, Pid, _} -> ok end
   end,
   fun(_) ->
     [?_assertEqual(pong, p70_alumbrado_publico_server:ping()),
      ?_assert(is_map(p70_alumbrado_publico_server:state()))]
   end}.
