-module(p70_registro_tests).
-include_lib("eunit/include/eunit.hrl").

%% Cada prueba arranca el arbol completo y espera a que termine al final.
registro_test_() ->
  {foreach,
   fun() -> {ok, Sup} = p70_alumbrado_publico_sup:start_link(), Sup end,
   fun(Sup) ->
     Ref = monitor(process, Sup),
     unlink(Sup),
     exit(Sup, shutdown),
     receive {'DOWN', Ref, process, Sup, _} -> ok end
   end,
   [fun quince_reportes_misma_falla/1,
    fun cuarenta_luminarias_cuarenta_fallas/1,
    fun reincidencia_abre_falla_nueva/1,
    fun falla_muerta_se_reemplaza/1]}.

%% Caso del escenario: 15 reportes del mismo poste -> una sola falla.
quince_reportes_misma_falla(_Sup) ->
  ?_test(begin
    L = <<"L-0100">>,
    {ok, Pid, nueva} = p70_registro:reportar(L, alta, {ciudadano, 1}),
    [{ok, Pid, agrupada} = p70_registro:reportar(L, alta, {ciudadano, N})
     || N <- lists:seq(2, 15)],
    ?assertMatch({reportada, #{reportes := 15}}, p70_falla:estado(Pid))
  end).

%% 40 luminarias distintas -> 40 fallas independientes.
cuarenta_luminarias_cuarenta_fallas(_Sup) ->
  ?_test(begin
    [{ok, _, nueva} = p70_registro:reportar(luminaria(N), media, telemetria)
     || N <- lists:seq(1, 40)],
    Conteo = supervisor:count_children(p70_falla_sup),
    ?assertEqual(40, proplists:get_value(active, Conteo))
  end).

%% Reincidencia: tras reparar, un reporte nuevo abre otra falla y se cuenta.
reincidencia_abre_falla_nueva(_Sup) ->
  ?_test(begin
    L = <<"L-0200">>,
    {ok, Pid1, nueva} = p70_registro:reportar(L, alta, ciudadano),
    ok = p70_falla:asignar(Pid1, cuadrilla_1),
    ok = p70_falla:reparar(Pid1),
    {ok, Pid2, reincidencia} = p70_registro:reportar(L, alta, ciudadano),
    ?assertNotEqual(Pid1, Pid2),
    ?assertEqual(1, p70_registro:reincidencias(L))
  end).

%% Si la falla muere, el siguiente reporte abre una nueva sin romper el registro.
falla_muerta_se_reemplaza(_Sup) ->
  ?_test(begin
    L = <<"L-0300">>,
    {ok, A, nueva} = p70_registro:reportar(L, alta, ciudadano),
    Ref = monitor(process, A),
    exit(A, kill),
    receive {'DOWN', Ref, process, A, _} -> ok end,
    {ok, B, nueva} = p70_registro:reportar(L, alta, ciudadano),
    ?assertNotEqual(A, B),
    ?assert(is_process_alive(B))
  end).

luminaria(N) ->
  iolist_to_binary(io_lib:format("L-~4..0w", [N])).
