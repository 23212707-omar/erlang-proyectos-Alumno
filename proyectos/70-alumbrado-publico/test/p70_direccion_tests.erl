-module(p70_direccion_tests).
-include_lib("eunit/include/eunit.hrl").

%% La misma direccion escrita de varias formas da la misma clave.
mismas_direcciones_escritas_distinto_test() ->
  Esperada = {ok, {["revolucion"], 1234}, ["centro"]},
  Formas = [<<"Av. Revolución #1234, Zona Centro"/utf8>>,
            <<"AVENIDA REVOLUCIÓN No. 1234 Col. Centro"/utf8>>,
            <<"avenida revolucion num 1234 centro">>,
            <<"av.revolucion#1234,zona centro">>],
  [?assertEqual(Esperada, p70_direccion:clave(Forma)) || Forma <- Formas].

sin_sector_test() ->
  ?assertEqual({ok, {["revolucion"], 1234}, []}, p70_direccion:clave(<<"  Av   Revolucion   #1234 ">>)).

calles_de_varias_palabras_test() ->
  ?assertEqual({ok, {["diaz", "ordaz"], 200}, ["playas"]},
               p70_direccion:clave(<<"Blvd. Díaz Ordaz #200, Playas de Tijuana"/utf8>>)),
  ?assertEqual({ok, {["heroes"], 150}, []}, p70_direccion:clave(<<"Paseo de los Héroes 150"/utf8>>)),
  ?assertEqual({ok, {["rapida"], 7}, []}, p70_direccion:clave(<<"Vía Rápida #7"/utf8>>)),
  ?assertEqual({ok, {["decima"], 5}, ["sanchez", "taboada"]},
               p70_direccion:clave(<<"Calle Décima #5, Sánchez Taboada"/utf8>>)).

%% "La Mesa" y "Mesa de Otay" no se confunden: se comparan sus palabras.
sectores_parecidos_test() ->
  {ok, _, La} = p70_direccion:clave(<<"Calle Quinta #100, La Mesa"/utf8>>),
  {ok, _, Otay} = p70_direccion:clave(<<"Calle Quinta #100, Mesa de Otay"/utf8>>),
  ?assertEqual(["mesa"], La),
  ?assertEqual(["mesa", "otay"], Otay).

direcciones_invalidas_test() ->
  ?assertEqual(error, p70_direccion:clave(<<>>)),
  ?assertEqual(error, p70_direccion:clave(<<"Av. Revolución"/utf8>>)),
  ?assertEqual(error, p70_direccion:clave(<<"1234">>)),
  ?assertEqual(error, p70_direccion:clave(<<255>>)),
  ?assertEqual(error, p70_direccion:clave(42)).
