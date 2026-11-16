% Pruebas con plunit. Uso: swipl -g run_tests -t halt pruebas.pl

:- use_module(library(plunit)).
:- use_module(library(aggregate)).
:- use_module(consultas).

:- begin_tests(peliculas).

test(base_cargada) :-
    aggregate_all(count, pelicula(_, _, _), N),
    N > 30000.

test(buscar_titulo, [nondet]) :-
    titulo_contiene(matrix, _, "The Matrix", 1999).

test(coactor_es_simetrico, [nondet]) :-
    coactor('Kevin Bacon', 'Meryl Streep', Id),
    coactor('Meryl Streep', 'Kevin Bacon', Id).

test(nueva_version_respeta_orden, [nondet]) :-
    nueva_version(_, A1, A2),
    A1 < A2.

test(carrera) :-
    carrera('Tom Hanks', Primer, Ultimo, N),
    Primer =< Ultimo, N > 10.

test(camino_directo) :-
    camino('Kevin Bacon', 'Meryl Streep', ['Kevin Bacon', paso(_, _), 'Meryl Streep']).

test(camino_actor_inexistente, [fail]) :-
    camino('Kevin Bacon', 'Nadie Que Exista', _).

test(similares_no_se_incluye_a_si_misma, [nondet]) :-
    titulo_contiene(matrix, Id, "The Matrix", 1999),
    similares(Id, 5, L),
    length(L, 5),
    \+ memberchk(_-Id, L).

:- end_tests(peliculas).
