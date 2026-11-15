%% Rutas de cuadrilla: agrupa las fallas por cercania geografica.
%% Funciones puras (sin procesos propios), salvo punto/1 que consulta el catalogo.
%%   punto(Id)            coordenadas de una luminaria o de un circuito
%%   distancia_km(A, B)   distancia entre dos puntos {Lat, Lon} (haversine)
%%   ordenar(Paradas)     vecino mas cercano, empezando por la primera parada
%%   ruta_cuadrilla(...)  ruta de una cuadrilla: paradas en orden y km totales
-module(p70_rutas).

-export([punto/1, distancia_km/2, ordenar/1, km_total/1, ruta_cuadrilla/1]).

-define(RADIO_TIERRA_KM, 6371.0).

%% {ok, {Lat, Lon}} | error. Id puede ser "L-0001" o un circuito "C-CEN-01".
punto(Id) ->
  case p70_catalogo:buscar(Id) of
    {ok, #{lat := Lat, lon := Lon}} ->
      {ok, {Lat, Lon}};
    error ->
      case p70_catalogo:circuito(Id) of
        {ok, #{lat := Lat, lon := Lon}} -> {ok, {Lat, Lon}};
        error -> error
      end
  end.

%% Distancia en km entre {Lat, Lon} y {Lat, Lon} (formula de haversine).
distancia_km({Lat1, Lon1}, {Lat2, Lon2}) ->
  Rad = fun(Grados) -> Grados * math:pi() / 180 end,
  DLat = Rad(Lat2 - Lat1),
  DLon = Rad(Lon2 - Lon1),
  A = math:pow(math:sin(DLat / 2), 2) +
      math:cos(Rad(Lat1)) * math:cos(Rad(Lat2)) * math:pow(math:sin(DLon / 2), 2),
  2 * ?RADIO_TIERRA_KM * math:asin(math:sqrt(A)).

%% Paradas: [{Id, {Lat, Lon}}]. Se queda con la primera (la mas urgente) y luego
%% va siempre a la parada pendiente mas cercana (vecino mas cercano).
ordenar([]) ->
  [];
ordenar([Primera | Resto]) ->
  ordenar([Primera], Resto).

ordenar(Ruta, []) ->
  lists:reverse(Ruta);
ordenar([{_, Actual} | _] = Ruta, Pendientes) ->
  {_, Id} = lists:min([{distancia_km(Actual, Punto), I} || {I, Punto} <- Pendientes]),
  {value, Siguiente, Resto} = lists:keytake(Id, 1, Pendientes),
  ordenar([Siguiente | Ruta], Resto).

%% Kilometros del recorrido por las paradas, en orden.
km_total(Paradas) ->
  Puntos = [P || {_, P} <- Paradas],
  case Puntos of
    [] -> 0.0;
    [_ | Siguientes] -> lists:sum([distancia_km(A, B) || {A, B} <- lists:zip(lists:droplast(Puntos), Siguientes)]) + 0.0
  end.

%% Fallas: [{Luminaria, Datos}] de una misma cuadrilla (Datos = mapa de p70_falla).
%% Empieza por la mas urgente (prioridad efectiva, mas reportes, mas antigua) y sigue
%% por cercania. Devuelve #{paradas := [...], distancia_km := Km}.
ruta_cuadrilla(Fallas) ->
  Con = [{Id, Punto, Datos} || {Id, Datos} <- Fallas, {ok, Punto} <- [punto(Id)]],
  Urgentes = lists:sort(fun({_, _, A}, {_, _, B}) -> clave(A) =< clave(B) end, Con),
  Ordenadas = ordenar([{Id, Punto} || {Id, Punto, _} <- Urgentes]),
  Paradas = lists:map(fun({Id, {Lat, Lon}}) ->
                         {_, _, Datos} = lists:keyfind(Id, 1, Urgentes),
                         #{luminaria => Id, lat => Lat, lon => Lon,
                           prioridad => p70_falla:prioridad_efectiva(Datos)}
                       end, Ordenadas),
  #{paradas => Paradas, distancia_km => redondear(km_total(Ordenadas))}.

clave(Datos) ->
  Rango = case p70_falla:prioridad_efectiva(Datos) of
            alta -> 0;
            media -> 1;
            baja -> 2
          end,
  {Rango, -maps:get(reportes, Datos), maps:get(reportada_en, Datos)}.

redondear(X) -> round(X * 100) / 100.
