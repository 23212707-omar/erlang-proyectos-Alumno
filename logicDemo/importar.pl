% Convierte datos/movies.json en hechos Prolog (datos/peliculas.pl).
% Uso: swipl importar.pl

:- use_module(library(http/json)).
:- use_module(library(apply)).

:- initialization(main, main).

main :-
    setup_call_cleanup(
        open('datos/movies.json', read, In, [encoding(utf8)]),
        json_read_dict(In, Peliculas),
        close(In)),
    setup_call_cleanup(
        open('datos/peliculas.pl', write, Out, [encoding(utf8)]),
        ( cabecera(Out),
          foldl(escribe(Out), Peliculas, 1, Siguiente) ),
        close(Out)),
    Total is Siguiente - 1,
    format("~D películas escritas en datos/peliculas.pl~n", [Total]).

cabecera(Out) :-
    format(Out, ":- encoding(utf8).~n", []),
    format(Out, ":- discontiguous pelicula/3, actua/2, genero/2, sinopsis/2.~n~n", []).

% Una película del JSON se reparte en varias relaciones, como en una base normalizada.
% Actores y géneros van como átomos: se comparan e indexan más rápido que las cadenas.
escribe(Out, P, Id, Id1) :-
    Id1 is Id + 1,
    format(Out, "~q.~n", [pelicula(Id, P.title, P.year)]),
    forall(( member(S, P.cast), atom_string(Actor, S) ),
           format(Out, "~q.~n", [actua(Id, Actor)])),
    forall(( member(S, P.genres), atom_string(Genero, S) ),
           format(Out, "~q.~n", [genero(Id, Genero)])),
    (   get_dict(extract, P, Texto)
    ->  format(Out, "~q.~n", [sinopsis(Id, Texto)])
    ;   true
    ).
