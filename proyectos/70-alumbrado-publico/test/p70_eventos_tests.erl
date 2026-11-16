-module(p70_eventos_tests).
-include_lib("eunit/include/eunit.hrl").

eventos_test_() ->
  {foreach,
   fun() -> {ok, Pid} = p70_eventos:start_link(), Pid end,
   fun(Pid) ->
     Ref = monitor(process, Pid),
     unlink(Pid),
     exit(Pid, shutdown),
     receive {'DOWN', Ref, process, Pid, _} -> ok end
   end,
   [fun publica_a_todos_los_suscriptores/1,
    fun suscribir_dos_veces_no_duplica/1,
    fun suscriptor_muerto_se_da_de_baja/1,
    fun publicar_sin_suscriptores_no_falla/1]}.

publica_a_todos_los_suscriptores(_Pid) ->
  ?_test(begin
    Otro = spawn_link(fun() -> receive {evento, E} -> receive {pedir, De} -> De ! {recibido, E} end end end),
    ok = p70_eventos:suscribir(self()),
    ok = p70_eventos:suscribir(Otro),
    p70_eventos:publicar(#{id => 1, tipo => nueva}),
    ?assertEqual(ok, receive {evento, #{id := 1}} -> ok after 1000 -> timeout end),
    Otro ! {pedir, self()},
    ?assertEqual(ok, receive {recibido, #{id := 1}} -> ok after 1000 -> timeout end)
  end).

suscribir_dos_veces_no_duplica(_Pid) ->
  ?_test(begin
    ok = p70_eventos:suscribir(self()),
    ok = p70_eventos:suscribir(self()),
    ?assertEqual([self()], p70_eventos:suscriptores()),
    p70_eventos:publicar(#{id => 2}),
    ?assertEqual(ok, receive {evento, #{id := 2}} -> ok after 1000 -> timeout end),
    %% Solo llego uno.
    ?assertEqual(vacio, receive {evento, _} -> otro after 100 -> vacio end)
  end).

suscriptor_muerto_se_da_de_baja(_Pid) ->
  ?_test(begin
    Muerto = spawn(fun() -> ok end),
    Ref = monitor(process, Muerto),
    receive {'DOWN', Ref, process, Muerto, _} -> ok end,
    ok = p70_eventos:suscribir(Muerto),
    %% La baja llega como mensaje 'DOWN' al canal; se espera a que se procese.
    ok = esperar_sin(Muerto, 20),
    ?assertEqual([], p70_eventos:suscriptores())
  end).

publicar_sin_suscriptores_no_falla(_Pid) ->
  ?_test(begin
    p70_eventos:publicar(#{id => 3}),
    ?assertEqual([], p70_eventos:suscriptores())
  end).

esperar_sin(_Pid, 0) ->
  error;
esperar_sin(Pid, N) ->
  case lists:member(Pid, p70_eventos:suscriptores()) of
    false -> ok;
    true -> timer:sleep(50), esperar_sin(Pid, N - 1)
  end.
