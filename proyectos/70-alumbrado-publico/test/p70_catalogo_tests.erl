-module(p70_catalogo_tests).
-include_lib("eunit/include/eunit.hrl").

catalogo_test_() ->
  {foreach,
   fun() -> {ok, Pid} = p70_catalogo:start_link(), Pid end,
   fun(Pid) ->
     Ref = monitor(process, Pid),
     unlink(Pid),
     exit(Pid, shutdown),
     receive {'DOWN', Ref, process, Pid, _} -> ok end
   end,
   [fun cinco_mil_luminarias_unicas/1,
    fun es_determinista_y_esta_en_tijuana/1,
    fun circuitos_de_a_lo_mas_40/1,
    fun buscar_existente_e_inexistente/1]}.

cinco_mil_luminarias_unicas(_Pid) ->
  ?_test(begin
    ?assertEqual(5000, ets:info(p70_catalogo, size)),
    #{total := Total, sectores := Sectores} = p70_catalogo:resumen(),
    ?assertEqual(5000, Total),
    ?assertEqual(5000, lists:sum([maps:get(luminarias, S) || S <- Sectores]))
  end).

%% Dos generaciones dan lo mismo, y todas caen dentro de una caja alrededor de Tijuana.
es_determinista_y_esta_en_tijuana(_Pid) ->
  ?_test(begin
    ?assertEqual(p70_catalogo:generar(200), p70_catalogo:generar(200)),
    Todas = p70_catalogo:generar(5000),
    ?assert(lists:all(fun(#{lat := Lat, lon := Lon}) ->
                        Lat > 32.40 andalso Lat < 32.62 andalso
                        Lon > -117.20 andalso Lon < -116.80
                      end, Todas)),
    %% Ninguna cae en el mar ni al norte de la frontera (contorno aproximado).
    ?assert(lists:all(fun(#{lat := Lat, lon := Lon}) ->
                        Lat < 32.534 + (Lon + 117.125) * 0.0923 andalso
                        Lon > -117.125 + (32.534 - Lat) * 0.22
                      end, Todas))
  end).

%% Cada circuito agrupa como maximo 40 luminarias y hay circuitos completos.
circuitos_de_a_lo_mas_40(_Pid) ->
  ?_test(begin
    PorCircuito = lists:foldl(fun(#{circuito := C}, Acc) ->
                                Acc#{C => maps:get(C, Acc, 0) + 1}
                              end, #{}, p70_catalogo:generar(5000)),
    Tamanos = maps:values(PorCircuito),
    ?assertEqual(40, lists:max(Tamanos)),
    ?assert(lists:all(fun(T) -> T =< 40 end, Tamanos))
  end).

buscar_existente_e_inexistente(_Pid) ->
  ?_test(begin
    ?assertMatch({ok, #{id := <<"L-0001">>, sector := _, lat := _, lon := _}},
                 p70_catalogo:buscar(<<"L-0001">>)),
    ?assertMatch({ok, #{id := <<"L-5000">>}}, p70_catalogo:buscar(<<"L-5000">>)),
    ?assertEqual(error, p70_catalogo:buscar(<<"L-9999">>))
  end).
