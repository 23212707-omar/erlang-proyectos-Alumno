% Servidor web de la demo. Solo traduce HTTP <-> consultas; ninguna regla vive aquí.
% Uso: swipl servidor.pl            (puerto 8080)
%      swipl servidor.pl 9000

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(solution_sequences)).
:- use_module(library(apply)).
:- use_module(consultas).

:- initialization(main, main).

:- http_handler(root(.),              inicio,        []).
:- http_handler(root(api/buscar),     api_buscar,    []).
:- http_handler(root(api/actor),      api_actor,     []).
:- http_handler(root(api/camino),     api_camino,    []).
:- http_handler(root(api/similares),  api_similares, []).
:- http_handler(root(api/generos),    api_generos,   []).

main(Argv) :-
    (   Argv = [A|_], atom_number(A, Puerto) -> true ; Puerto = 8080 ),
    servidor(Puerto),
    thread_get_message(_).          % mantiene vivo el proceso

servidor(Puerto) :-
    http_server(http_dispatch, [port(Puerto)]),
    format("Demo en http://localhost:~w/~n", [Puerto]).

inicio(Peticion) :-
    http_reply_file('web/index.html', [], Peticion).

% GET /api/buscar?q=matrix
api_buscar(Peticion) :-
    http_parameters(Peticion, [q(Q, [length >= 2])]),
    findall(D, limit(50, ( titulo_contiene(Q, Id, T, A), ficha(Id, T, A, D) )), L),
    reply_json_dict(L).

% GET /api/actor?nombre=Tom Hanks
api_actor(Peticion) :-
    http_parameters(Peticion, [nombre(Actor, [])]),
    (   carrera(Actor, Primer, Ultimo, Cuantas)
    ->  filmografia(Actor, Pelis),
        maplist([A-T, _{anio:A, titulo:T}]>>true, Pelis, Filmografia),
        companeros(Actor, 10, Cs),
        maplist([C-B, _{actor:B, veces:C}]>>true, Cs, Companeros),
        reply_json_dict(_{actor:Actor, primer:Primer, ultimo:Ultimo, peliculas:Cuantas,
                          filmografia:Filmografia, companeros:Companeros})
    ;   no_encontrado(Actor)
    ).

% GET /api/camino?de=Kevin Bacon&a=Meryl Streep
api_camino(Peticion) :-
    http_parameters(Peticion, [de(A, []), a(B, [])]),
    (   camino(A, B, Camino)
    ->  maplist(paso_json, Camino, Pasos),
        length(Camino, N),
        Grados is N // 2,
        reply_json_dict(_{grados:Grados, camino:Pasos})
    ;   reply_json_dict(_{error:"sin camino (o algún actor no existe)"}, [status(404)])
    ).

% GET /api/similares?id=123
api_similares(Peticion) :-
    http_parameters(Peticion, [id(Id, [integer])]),
    similares(Id, 10, L),
    maplist([P-Otra, D]>>( pelicula(Otra, T, A), ficha(Otra, T, A, D0),
                           put_dict(puntos, D0, P, D) ), L, Ds),
    reply_json_dict(Ds).

% GET /api/generos
api_generos(_) :-
    findall(_{genero:G, peliculas:N},
            order_by([desc(N)], conteo_genero(G, N)), L),
    reply_json_dict(L).

ficha(Id, Titulo, Anio, _{id:Id, titulo:Titulo, anio:Anio, generos:Gs, reparto:As}) :-
    findall(G, genero(Id, G), Gs),
    findall(A, actua(Id, A), As).

paso_json(paso(Titulo, Anio), _{pelicula:Titulo, anio:Anio}) :- !.
paso_json(Actor, _{actor:Actor}).

no_encontrado(Que) :-
    reply_json_dict(_{error:"no encontrado", valor:Que}, [status(404)]).
