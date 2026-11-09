-module(p70_simulador_tests).
-include_lib("eunit/include/eunit.hrl").

%% Cada prueba arranca el arbol completo (el simulador es el ultimo hijo) y lo detiene
%% de forma sincrona al terminar. Se usa tick/0 para no depender del reloj.
simulador_test_() ->
  {foreach,
   fun() ->
     {ok, Sup} = p70_alumbrado_publico_sup:start_link(),
     Sup
   end,
   fun(Sup) ->
     Ref = monitor(process, Sup),
     unlink(Sup),
     exit(Sup, shutdown),
     receive {'DOWN', Ref, process, Sup, _} -> ok end
   end,
   [fun los_pasos_cuentan_reportes/1,
    fun despacha_repara_y_respeta_la_capacidad/1,
    fun iniciar_y_detener/1,
    fun escenario_de_quince_reportes_en_un_poste/1,
    fun escenario_de_circuito_completo/1]}.

los_pasos_cuentan_reportes(_Sup) ->
  ?_test(begin
    lists:foreach(fun(_) -> p70_simulador:tick() end, lists:seq(1, 20)),
    #{ticks := Ticks, reportes := Reportes, nuevas := N, agrupadas := A, reincidencias := R} =
      p70_simulador:estado(),
    ?assertEqual(20, Ticks),
    ?assertEqual(20, Reportes),
    ?assertEqual(20, N + A + R)
  end).

despacha_repara_y_respeta_la_capacidad(_Sup) ->
  ?_test(begin
    lists:foreach(fun(_) -> p70_simulador:tick() end, lists:seq(1, 60)),
    #{asignadas := Asignadas, reparadas := Reparadas} = p70_simulador:estado(),
    ?assert(Asignadas > 0),
    ?assert(Reparadas > 0),
    %% Ninguna cuadrilla tiene mas de 3 fallas asignadas a la vez.
    Cargas = lists:foldl(fun(Pid, Acc) ->
                           case p70_falla:estado(Pid) of
                             {asignada, #{asignada_a := C}} -> Acc#{C => maps:get(C, Acc, 0) + 1};
                             _ -> Acc
                           end
                         end, #{}, maps:values(p70_registro:activas())),
    ?assert(lists:all(fun(N) -> N =< 3 end, maps:values(Cargas)))
  end).

iniciar_y_detener(_Sup) ->
  ?_test(begin
    ?assertMatch(#{activo := false}, p70_simulador:estado()),
    ?assertMatch(#{activo := true}, p70_simulador:iniciar()),
    ?assertMatch(#{activo := false}, p70_simulador:detener()),
    ?assertMatch(#{activo := false}, p70_simulador:estado())
  end).

%% Escenario: 15 reportes del mismo poste -> una sola falla con 15 reportes.
escenario_de_quince_reportes_en_un_poste(_Sup) ->
  ?_test(begin
    {ok, Resumen} = p70_simulador:escenario_poste(<<"L-0777">>),
    ?assertMatch(#{enviados := 15, nuevas := 1, agrupadas := 14, reincidencias := 0}, Resumen),
    {ok, Pid} = p70_registro:buscar(<<"L-0777">>),
    ?assertMatch({reportada, #{reportes := 15}}, p70_falla:estado(Pid)),
    ?assertEqual({error, luminaria_desconocida}, p70_simulador:escenario_poste(<<"L-9999">>))
  end).

%% Escenario: falla de un circuito completo (40 luminarias).
escenario_de_circuito_completo(_Sup) ->
  ?_test(begin
    {ok, Resumen} = p70_simulador:escenario_circuito(<<"C-CEN-01">>),
    ?assertMatch(#{luminarias := 40, nuevas := 40, agrupadas := 0}, Resumen),
    ?assertEqual(40, map_size(p70_registro:activas())),
    ?assertEqual({error, circuito_desconocido}, p70_simulador:escenario_circuito(<<"C-XXX-99">>))
  end).
