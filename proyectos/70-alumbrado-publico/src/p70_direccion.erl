%% Normalizacion de direcciones escritas a mano. El documento del problema pide
%% detectar duplicados aunque la direccion este escrita distinto: "Av. Revolucion
%% #1234", "AVENIDA REVOLUCIÓN No. 1234, Col. Centro" y "av revolucion 1234" son
%% el mismo poste.
%%
%% Cada texto se reduce a una clave {palabras de la calle, numero} y a las palabras
%% del sector (si las trae). Se quitan acentos, mayusculas, puntuacion, el tipo de
%% via (av, blvd, calle, paseo...) y palabras de relleno (de, la, no, col...).
%% Con esa clave se busca en un indice del catalogo simulado (se arma una vez).
-module(p70_direccion).

-export([clave/1, resolver/1]).

-define(TIPOS, ["av", "avenida", "blvd", "boulevard", "bulevar", "bvd", "calle", "cll",
                "c", "paseo", "via", "calz", "calzada"]).
-define(RUIDO_CALLE, ["de", "del", "la", "los", "las", "no", "num", "numero", "n"]).
-define(RUIDO_SECTOR, ["col", "colonia", "zona", "de", "del", "la", "los", "las",
                       "tijuana", "bc", "cp", "fracc", "fraccionamiento"]).

%% {ok, {PalabrasCalle, Numero}, PalabrasSector} | error
%% Necesita al menos una palabra de calle antes del numero y un numero.
clave(Texto) ->
  case tokens(Texto) of
    error ->
      error;
    Tokens ->
      {Antes, Resto} = lists:splitwith(fun(T) -> not es_numero(T) end, Tokens),
      Calle = [T || T <- Antes,
                    not lists:member(T, ?TIPOS),
                    not lists:member(T, ?RUIDO_CALLE)],
      case {Calle, Resto} of
        {[_ | _], [Numero | Despues]} ->
          Sector = [T || T <- Despues,
                         not es_numero(T),
                         not lists:member(T, ?RUIDO_SECTOR)],
          {ok, {Calle, list_to_integer(Numero)}, lists:sort(Sector)};
        _ ->
          error
      end
  end.

%% {ok, IdLuminaria} | {error, direccion_invalida | no_encontrada | {ambigua, [Id]}}
%% Si el texto trae sector se usa para filtrar; si aun quedan varias luminarias con
%% la misma direccion (dos postes en el mismo numero) es ambigua.
resolver(Texto) ->
  case clave(Texto) of
    error ->
      {error, direccion_invalida};
    {ok, Llave, Sector} ->
      Candidatas = maps:get(Llave, indice(), []),
      case filtrar_sector(Candidatas, Sector) of
        [] -> {error, no_encontrada};
        [{Id, _}] -> {ok, Id};
        Varias -> {error, {ambigua, lists:sort([Id || {Id, _} <- Varias])}}
      end
  end.

%% --- Internas ---

%% Prefiere el sector escrito igual; si no, el que contiene todas las palabras dadas
%% ("La Mesa" vs "Mesa de Otay": "mesa" sola es ambigua, "mesa otay" no).
filtrar_sector(Candidatas, []) ->
  Candidatas;
filtrar_sector(Candidatas, Sector) ->
  case [C || {_, S} = C <- Candidatas, S =:= Sector] of
    [] -> [C || {_, S} = C <- Candidatas, (Sector -- S) =:= []];
    Iguales -> Iguales
  end.

%% Palabras en minuscula, sin acentos ni signos. error si el texto no es valido.
tokens(Texto) when is_binary(Texto) ->
  case unicode:characters_to_nfd_list(Texto) of
    Lista when is_list(Lista) ->
      Sin = [C || C <- Lista, C < 16#300 orelse C > 16#36F],
      Min = string:lowercase(Sin),
      Limpio = [case es_alfanumerico(C) of true -> C; false -> $\s end || C <- Min],
      string:lexemes(Limpio, " ");
    _ ->
      error
  end;
tokens(_) ->
  error.

es_alfanumerico(C) ->
  (C >= $a andalso C =< $z) orelse (C >= $0 andalso C =< $9).

es_numero(T) ->
  lists:all(fun(C) -> C >= $0 andalso C =< $9 end, T).

%% Llave => [{Id, PalabrasSector}]. Se guarda en persistent_term: el catalogo es
%% determinista, asi que no cambia. Si el catalogo aun no esta listo no se guarda.
indice() ->
  case persistent_term:get({?MODULE, indice}, undefined) of
    undefined -> construir();
    Indice -> Indice
  end.

construir() ->
  Ids = [Id || [Id, _, _] <- p70_catalogo:puntos()],
  Indice = lists:foldl(fun(Id, Acc) -> indexar(Id, Acc) end, #{}, Ids),
  case Ids of
    [] -> ok;
    _ -> persistent_term:put({?MODULE, indice}, Indice)
  end,
  Indice.

indexar(Id, Acc) ->
  case p70_catalogo:buscar(Id) of
    {ok, #{direccion := Direccion}} ->
      case clave(Direccion) of
        {ok, Llave, Sector} ->
          maps:update_with(Llave, fun(Lista) -> [{Id, Sector} | Lista] end,
                           [{Id, Sector}], Acc);
        error ->
          Acc
      end;
    _ ->
      Acc
  end.
