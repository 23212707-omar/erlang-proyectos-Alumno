-module(p70_rutas_tests).
-include_lib("eunit/include/eunit.hrl").

%% Un grado de latitud son unos 111 km.
distancia_haversine_test() ->
  D = p70_rutas:distancia_km({32.5, -117.0}, {32.6, -117.0}),
  ?assert(D > 11.0 andalso D < 11.3),
  ?assertEqual(0.0, p70_rutas:distancia_km({32.5, -117.0}, {32.5, -117.0})).

%% Empieza por la primera parada y va siempre a la mas cercana.
vecino_mas_cercano_test() ->
  A = {<<"A">>, {32.5, -117.00}},
  B = {<<"B">>, {32.5, -116.70}},
  C = {<<"C">>, {32.5, -116.90}},
  D = {<<"D">>, {32.5, -116.80}},
  Orden = [Id || {Id, _} <- p70_rutas:ordenar([A, B, C, D])],
  ?assertEqual([<<"A">>, <<"C">>, <<"D">>, <<"B">>], Orden),
  ?assertEqual([], p70_rutas:ordenar([])).

km_totales_test() ->
  Paradas = [{<<"A">>, {32.5, -117.0}}, {<<"B">>, {32.6, -117.0}}, {<<"C">>, {32.7, -117.0}}],
  Km = p70_rutas:km_total(Paradas),
  ?assert(Km > 22.0 andalso Km < 22.5),
  ?assertEqual(0.0, p70_rutas:km_total([])),
  ?assertEqual(0.0, p70_rutas:km_total([{<<"A">>, {32.5, -117.0}}])).
