% Reglas sobre la base de películas. Los hechos viven en datos/peliculas.pl:
%
%   pelicula(Id, Titulo, Anio).    actua(Id, Actor).
%   genero(Id, Genero).            sinopsis(Id, Texto).

:- module(consultas,
          [ pelicula/3, actua/2, genero/2, sinopsis/2,
            titulo_contiene/4, filmografia/2, coactor/3, decada/2,
            nueva_version/3, sin_reparto/1, solo_genero/2,
            conteo_genero/2, mas_activos/2, carrera/4,
            companeros/3, similares/3, camino/3
          ]).

:- use_module(library(aggregate)).
:- use_module(library(solution_sequences)).
:- use_module(library(assoc)).
:- use_module(library(apply)).
:- use_module(library(lists)).

:- load_files('datos/peliculas', [if(not_loaded)]).

% --- Reglas simples: cada una es una consulta con nombre -----------------------

%! titulo_contiene(+Texto, -Id, -Titulo, -Anio) is nondet.
%  Una solución por cada película cuyo título contiene Texto (sin distinguir mayúsculas).
titulo_contiene(Texto, Id, Titulo, Anio) :-
    pelicula(Id, Titulo, Anio),
    sub_atom_icasechk(Titulo, _, Texto).

%! filmografia(+Actor, -Peliculas) is det.
%  Lista Anio-Titulo ordenada. findall/3 junta todas las soluciones del backtracking.
filmografia(Actor, Peliculas) :-
    findall(Anio-Titulo, ( actua(Id, Actor), pelicula(Id, Titulo, Anio) ), L),
    msort(L, Peliculas).

%! coactor(?A, ?B, ?Id) is nondet.
%  La misma regla sirve en todas direcciones: quién actuó con A, en qué película
%  coincidieron A y B, o todas las parejas de una película.
coactor(A, B, Id) :-
    actua(Id, A),
    actua(Id, B),
    A \== B.

decada(Id, Decada) :-
    pelicula(Id, _, Anio),
    Decada is Anio // 10 * 10.

%! nueva_version(?Titulo, -Anio1, -Anio2) is nondet.
%  Mismo título, años distintos: un auto-join.
nueva_version(Titulo, Anio1, Anio2) :-
    pelicula(Id1, Titulo, Anio1),
    pelicula(Id2, Titulo, Anio2),
    Id1 \== Id2,
    Anio1 < Anio2.

% Negación por falla: «no consta ningún actor», no «no tiene actores».
sin_reparto(Id) :-
    pelicula(Id, _, _),
    \+ actua(Id, _).

%! solo_genero(+Actor, ?Genero) is nondet.
%  Cuantificador universal: todas las películas del actor son de ese género.
solo_genero(Actor, Genero) :-
    genero(_, Genero),
    forall(actua(Id, Actor), genero(Id, Genero)),
    !.

% --- Agregación ------------------------------------------------------------------

%! conteo_genero(?Genero, -N) is nondet.
%  Como GROUP BY: al reintentar da el siguiente género con su conteo.
conteo_genero(Genero, N) :-
    aggregate(count, Id^genero(Id, Genero), N).

%! mas_activos(+N, -Lista) is det.
%  Los N actores con más películas, como Cuantas-Actor.
mas_activos(N, Lista) :-
    findall(C-A,
            limit(N, order_by([desc(C)],
                              aggregate(count, Id^actua(Id, A), C))),
            Lista).

%! carrera(+Actor, -Primer, -Ultimo, -Cuantas) is semidet.
carrera(Actor, Primer, Ultimo, Cuantas) :-
    aggregate(r(min(A), max(A), count),
              Id^T^( actua(Id, Actor), pelicula(Id, T, A) ),
              r(Primer, Ultimo, Cuantas)).

%! companeros(+Actor, +N, -Lista) is det.
%  Con quién ha trabajado más veces: Veces-Otro.
companeros(Actor, N, Lista) :-
    findall(C-B,
            limit(N, order_by([desc(C)],
                              aggregate(count, Id^coactor(Actor, B, Id), C))),
            Lista).

% --- Recomendación: puntos por reparto y género compartidos ----------------------

afinidad(Id, Otra, 3) :- actua(Id, A), actua(Otra, A), Otra \== Id.
afinidad(Id, Otra, 1) :- genero(Id, G), genero(Otra, G), Otra \== Id.

%! similares(+Id, +N, -Lista) is det.
%  Las N películas más afines, como Puntos-IdOtra.
similares(Id, N, Lista) :-
    findall(P-Otra,
            limit(N, order_by([desc(P)],
                              aggregate(sum(X), afinidad(Id, Otra, X), P))),
            Lista).

% --- Grafo de actores: camino más corto (el «número de Bacon») --------------------

%! camino(+A, +B, -Camino) is semidet.
%  Camino = [A, paso(Titulo, Anio), Actor, ..., B], el más corto, hasta 6 saltos.
%  Búsqueda en anchura; la tabla de visitados (library(assoc)) recuerda por dónde se llegó.
camino(A, B, Camino) :-
    actua(_, A), actua(_, B), !,
    list_to_assoc([A-inicio], V0),
    bfs([A], B, 6, V0, V),
    reconstruye(B, V, [], Camino).

bfs(_, B, _, V, V) :-
    get_assoc(B, V, _), !.
bfs(Frontera, B, N, V0, V) :-
    N > 0, Frontera \== [],
    foldl(expande, Frontera, V0-[], V1-Nueva),
    N1 is N - 1,
    bfs(Nueva, B, N1, V1, V).

expande(Actor, Estado0, Estado) :-
    findall(Otro-Id, ( actua(Id, Actor), actua(Id, Otro) ), Vecinos),
    foldl(visita(Actor), Vecinos, Estado0, Estado).

visita(Desde, Otro-Id, V0-F0, V-F) :-
    (   get_assoc(Otro, V0, _)
    ->  V = V0, F = F0
    ;   put_assoc(Otro, V0, via(Desde, Id), V),
        F = [Otro|F0]
    ).

reconstruye(A, V, Acc, Camino) :-
    get_assoc(A, V, Como),
    (   Como == inicio
    ->  Camino = [A|Acc]
    ;   Como = via(Anterior, Id),
        pelicula(Id, Titulo, Anio),
        reconstruye(Anterior, V, [paso(Titulo, Anio), A|Acc], Camino)
    ).
