-module(p70_bitacora_tests).
-include_lib("eunit/include/eunit.hrl").

bitacora_test_() ->
  {foreach,
   fun() -> {ok, Pid} = p70_bitacora:start_link(), Pid end,
   fun(Pid) ->
     Ref = monitor(process, Pid),
     unlink(Pid),
     exit(Pid, shutdown),
     receive {'DOWN', Ref, process, Pid, _} -> ok end
   end,
   [fun mas_reciente_primero/1,
    fun solo_guarda_los_ultimos_200/1]}.

mas_reciente_primero(_Pid) ->
  ?_test(begin
    p70_bitacora:registrar(nueva, <<"L-1">>, #{}),
    p70_bitacora:registrar(asignada, <<"L-1">>, #{cuadrilla => c1}),
    [Ultimo, Primero] = p70_bitacora:ultimos(10),
    ?assertMatch(#{id := 2, tipo := asignada}, Ultimo),
    ?assertMatch(#{id := 1, tipo := nueva}, Primero)
  end).

solo_guarda_los_ultimos_200(_Pid) ->
  ?_test(begin
    [p70_bitacora:registrar(nueva, <<"L-1">>, #{}) || _ <- lists:seq(1, 250)],
    Eventos = p70_bitacora:ultimos(1000),
    ?assertEqual(200, length(Eventos)),
    ?assertMatch(#{id := 250}, hd(Eventos))
  end).
