%% Catalogo SIMULADO de luminarias: 5,000 puntos generados de forma determinista
%% (siempre salen los mismos) con sector, direccion, coordenadas aproximadas,
%% circuito, tipo de lugar y tecnologia. NO son datos reales del municipio.
%%
%% Vive en una tabla ETS (read_concurrency) cuyo dueno es este gen_server: las
%% lecturas (buscar/1) van directo a la tabla y no pasan por el proceso.
-module(p70_catalogo).
-behaviour(gen_server).

-export([start_link/0, buscar/1, resumen/0, puntos/0, generar/1, luminarias_de_circuito/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TABLA, p70_catalogo).
-define(TOTAL, 5000).
-define(POR_CIRCUITO, 40).

%% {Nombre, Codigo, LatCentro, LonCentro, Dispersion en grados, Peso}
%% Coordenadas aproximadas, solo para la simulacion.
-define(SECTORES, [
  {<<"Zona Centro"/utf8>>,        <<"CEN">>, 32.5320, -117.0380, 0.0070, 16},
  {<<"Zona Río"/utf8>>,           <<"RIO">>, 32.5260, -117.0220, 0.0070, 14},
  {<<"Playas de Tijuana"/utf8>>,  <<"PLA">>, 32.5170, -117.1050, 0.0070, 10},
  {<<"Mesa de Otay"/utf8>>,       <<"OTA">>, 32.5310, -116.9550, 0.0100, 14},
  {<<"La Mesa"/utf8>>,            <<"MES">>, 32.5120, -117.0000, 0.0100, 14},
  {<<"Sánchez Taboada"/utf8>>,    <<"SAN">>, 32.4680, -117.0000, 0.0110, 12},
  {<<"Zona Este"/utf8>>,          <<"EST">>, 32.5000, -116.8850, 0.0150, 12}
]).

-define(CALLES, {
  <<"Av. Revolución"/utf8>>, <<"Blvd. Agua Caliente"/utf8>>, <<"Paseo de los Héroes"/utf8>>,
  <<"Calle Segunda"/utf8>>, <<"Av. Constitución"/utf8>>, <<"Blvd. Díaz Ordaz"/utf8>>,
  <<"Vía Rápida"/utf8>>, <<"Av. Padre Kino"/utf8>>, <<"Calle Quinta"/utf8>>,
  <<"Blvd. Insurgentes"/utf8>>, <<"Av. Internacional"/utf8>>, <<"Calle Décima"/utf8>>
}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% {ok, Mapa} | error. Si la tabla no existe (el proceso se esta reiniciando) -> error.
buscar(Id) ->
  try ets:lookup(?TABLA, Id) of
    [{_, Luminaria}] -> {ok, Luminaria};
    [] -> error
  catch
    error:badarg -> error
  end.

%% Ids de las luminarias de un circuito, ordenados ([] si el circuito no existe).
luminarias_de_circuito(Circuito) ->
  try
    lists:sort([Id || {Id, #{circuito := C}} <- ets:tab2list(?TABLA), C =:= Circuito])
  catch
    error:badarg -> []
  end.

%% Totales por sector (luminarias y circuitos).
resumen() ->
  try
    Luminarias = [L || {_, L} <- ets:tab2list(?TABLA)],
    PorSector = lists:foldl(fun(#{sector := S, circuito := C}, Acc) ->
                              {N, Circuitos} = maps:get(S, Acc, {0, #{}}),
                              Acc#{S => {N + 1, Circuitos#{C => true}}}
                            end, #{}, Luminarias),
    Sectores = [#{sector => S, luminarias => N, circuitos => map_size(Circuitos)}
                || {S, {N, Circuitos}} <- lists:sort(maps:to_list(PorSector))],
    #{total => length(Luminarias),
      circuitos => lists:sum([maps:get(circuitos, X) || X <- Sectores]),
      sectores => Sectores}
  catch
    error:badarg -> #{total => 0, circuitos => 0, sectores => []}
  end.

%% [[Id, Lat, Lon], ...] ordenado por id (formato compacto para dibujar el mapa).
puntos() ->
  try
    lists:sort([[Id, Lat, Lon] || {Id, #{lat := Lat, lon := Lon}} <- ets:tab2list(?TABLA)])
  catch
    error:badarg -> []
  end.

%% --- gen_server ---

init([]) ->
  ?TABLA = ets:new(?TABLA, [named_table, protected, set, {read_concurrency, true}]),
  true = ets:insert(?TABLA, [{maps:get(id, L), L} || L <- generar(?TOTAL)]),
  logger:info("catalogo simulado generado", #{luminarias => ?TOTAL}),
  {ok, #{}}.

handle_call(_Pedido, _From, State) ->
  {reply, {error, no_soportado}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

%% --- Generacion determinista (sin estado aleatorio: todo sale de phash2) ---

generar(Total) ->
  {Lista, _} = lists:mapfoldl(fun(N, Contadores) ->
    {Nombre, Codigo, LatC, LonC, Dispersion, _Peso} = sector_de(N),
    Posicion = maps:get(Codigo, Contadores, 0),
    {Lat, Lon} = dentro_de_tierra(LatC + ruido(N, lat) * Dispersion,
                                  LonC + ruido(N, lon) * Dispersion),
    Luminaria = #{id => id(N),
                  sector => Nombre,
                  direccion => direccion(N, Nombre),
                  lat => redondear(Lat),
                  lon => redondear(Lon),
                  circuito => circuito(Codigo, Posicion div ?POR_CIRCUITO + 1),
                  lugar => lugar(N),
                  tecnologia => tecnologia(N)},
    {Luminaria, Contadores#{Codigo => Posicion + 1}}
  end, #{}, lists:seq(1, Total)),
  Lista.

%% Contorno APROXIMADO de la ciudad: la frontera con EE. UU. al norte y la costa del
%% Pacifico al oeste. Un punto que se sale se refleja hacia adentro para que ninguna
%% luminaria caiga en el mar ni del otro lado de la frontera.
borde(Lon) -> 32.534 + (Lon + 117.125) * 0.0923.
costa(Lat) -> -117.125 + (32.534 - Lat) * 0.22.

dentro_de_tierra(Lat, Lon) ->
  Lat1 = reflejar_max(Lat, borde(Lon) - 0.003),
  Lon1 = reflejar_min(Lon, costa(Lat1) + 0.003),
  {Lat1, Lon1}.

reflejar_max(V, Max) when V > Max -> Max - (V - Max);
reflejar_max(V, _Max) -> V.

reflejar_min(V, Min) when V < Min -> Min + (Min - V);
reflejar_min(V, _Min) -> V.

%% Numero pseudoaleatorio estable en [0, 1) para (N, Sal).
azar(N, Sal) ->
  erlang:phash2({N, Sal}, 1000000) / 1000000.0.

%% Aproximadamente normal (suma de tres uniformes), en [-3, 3].
ruido(N, Eje) ->
  (azar(N, {Eje, 1}) + azar(N, {Eje, 2}) + azar(N, {Eje, 3}) - 1.5) * 2.0.

sector_de(N) ->
  PesoTotal = lists:sum([P || {_, _, _, _, _, P} <- ?SECTORES]),
  elegir_sector(?SECTORES, azar(N, sector) * PesoTotal).

elegir_sector([Sector], _Objetivo) -> Sector;
elegir_sector([{_, _, _, _, _, Peso} = Sector | Resto], Objetivo) ->
  case Objetivo < Peso of
    true -> Sector;
    false -> elegir_sector(Resto, Objetivo - Peso)
  end.

id(N) ->
  iolist_to_binary(io_lib:format("L-~4..0w", [N])).

circuito(Codigo, Numero) ->
  iolist_to_binary(io_lib:format("C-~s-~2..0w", [Codigo, Numero])).

direccion(N, Sector) ->
  Calle = element(1 + erlang:phash2({N, calle}, tuple_size(?CALLES)), ?CALLES),
  Numero = 100 + erlang:phash2({N, numero}, 4900),
  iolist_to_binary([Calle, <<" #"/utf8>>, integer_to_binary(Numero), <<", "/utf8>>, Sector]).

%% Tipo de lugar: sirve despues para la prioridad por criticidad.
lugar(N) ->
  U = azar(N, lugar),
  if
    U < 0.30 -> avenida;
    U < 0.75 -> calle;
    U < 0.83 -> cruce_escolar;
    U < 0.86 -> hospital;
    true -> andador
  end.

tecnologia(N) ->
  case azar(N, tecnologia) < 0.70 of
    true -> led;
    false -> sodio
  end.

redondear(X) ->
  round(X * 1.0e5) / 1.0e5.
