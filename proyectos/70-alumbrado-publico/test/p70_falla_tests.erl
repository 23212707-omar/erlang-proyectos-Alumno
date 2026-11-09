-module(p70_falla_tests).
-include_lib("eunit/include/eunit.hrl").

%% Cada prueba arranca su propio supervisor de fallas y espera a que termine,
%% para que la siguiente no choque con el nombre registrado.
falla_test_() ->
  {foreach,
   fun() -> {ok, Sup} = p70_falla_sup:start_link(), Sup end,
   fun(Sup) ->
     Ref = monitor(process, Sup),
     unlink(Sup),
     exit(Sup, shutdown),
     receive {'DOWN', Ref, process, Sup, _} -> ok end
   end,
   [fun ciclo_completo/1,
    fun quince_reportes_una_falla/1,
    fun orden_invalido/1,
    fun reporte_tras_reparar/1,
    fun aislamiento_de_fallos/1]}.

ciclo_completo(_Sup) ->
  ?_test(begin
    {ok, F} = p70_falla_sup:abrir(<<"L-0001">>, alta, ciudadano),
    ?assertMatch({reportada, #{reportes := 1}}, p70_falla:estado(F)),
    ?assertEqual(ok, p70_falla:asignar(F, cuadrilla_1)),
    ?assertMatch({asignada, #{asignada_a := cuadrilla_1}}, p70_falla:estado(F)),
    ?assertEqual(ok, p70_falla:reparar(F)),
    {Estado, Datos} = p70_falla:estado(F),
    ?assertEqual(reparada, Estado),
    ?assert(is_integer(maps:get(reparada_en, Datos)))
  end).

%% Caso del escenario: 15 reportes del mismo poste -> una sola falla.
quince_reportes_una_falla(_Sup) ->
  ?_test(begin
    {ok, F} = p70_falla_sup:abrir(<<"L-0002">>, media, {ciudadano, 1}),
    [ok = p70_falla:reportar(F, {ciudadano, N}) || N <- lists:seq(2, 15)],
    {reportada, Datos} = p70_falla:estado(F),
    ?assertEqual(15, maps:get(reportes, Datos)),
    ?assertEqual(15, length(maps:get(fuentes, Datos)))
  end).

orden_invalido(_Sup) ->
  ?_test(begin
    {ok, F} = p70_falla_sup:abrir(<<"L-0003">>, baja, telemetria),
    ?assertEqual({error, {evento_invalido, reparar, reportada}}, p70_falla:reparar(F)),
    ?assertMatch({reportada, _}, p70_falla:estado(F))
  end).

%% Reincidencia: tras reparar, un reporte nuevo no reabre la falla cerrada.
reporte_tras_reparar(_Sup) ->
  ?_test(begin
    {ok, F} = p70_falla_sup:abrir(<<"L-0004">>, alta, ciudadano),
    ok = p70_falla:asignar(F, cuadrilla_2),
    ok = p70_falla:reparar(F),
    ?assertEqual({error, falla_cerrada}, p70_falla:reportar(F, ciudadano))
  end).

%% Mini prueba de caos: matar una falla no afecta a otra ni al supervisor.
aislamiento_de_fallos(_Sup) ->
  ?_test(begin
    {ok, A} = p70_falla_sup:abrir(<<"L-0005">>, alta, ciudadano),
    {ok, B} = p70_falla_sup:abrir(<<"L-0006">>, alta, ciudadano),
    Ref = monitor(process, A),
    exit(A, kill),
    receive {'DOWN', Ref, process, A, _} -> ok end,
    ?assert(is_process_alive(B)),
    ?assert(is_pid(whereis(p70_falla_sup))),
    ?assertMatch({reportada, _}, p70_falla:estado(B))
  end).
