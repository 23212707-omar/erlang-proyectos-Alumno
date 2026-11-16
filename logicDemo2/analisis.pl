% Prolog deduce los datos y llama a Python (Janus) solo para calcular o dibujar.
% Reutiliza la base y las reglas de ../logicDemo.

:- module(analisis,
          [ reparto_tipico/2,
            grafica_decadas/1, grafica_generos/1, grafica_actor/2,
            red_de/2, grafica_red/2, centrales/3
          ]).

:- reexport(library(janus)).        % deja py_call/2 disponible también en la consola
:- use_module(library(aggregate)).
:- use_module(library(pairs)).
:- use_module(library(lists)).
:- use_module(library(filesex)).
:- use_module('../logicDemo/consultas').

% Para que Python encuentre graficas.py, que vive junto a este archivo.
:- prolog_load_context(directory, Dir), py_add_lib_dir(Dir).

% --- Sin dependencias: la biblioteca estándar de Python --------------------------

%! reparto_tipico(-Media, -Mediana) is det.
%  Tamaño del reparto de una película. Prolog junta los números; Python hace la estadística.
reparto_tipico(Media, Mediana) :-
    findall(N,
            ( pelicula(Id, _, _),
              aggregate_all(count, actua(Id, _), N),
              N > 0 ),
            Ns),
    py_call(statistics:mean(Ns), Media),
    py_call(statistics:median(Ns), Mediana).

% --- Gráficas con matplotlib ------------------------------------------------------

%! grafica_decadas(-Archivo) is det.
grafica_decadas(Archivo) :-
    findall(D-N, aggregate(count, Id^decada(Id, D), N), Pares),
    pairs_keys_values(Pares, Decadas, Cuantas),
    salida('decadas.png', Archivo),
    py_call(graficas:barras("Películas por década", Decadas, Cuantas, Archivo), _).

%! grafica_generos(-Archivo) is det.
grafica_generos(Archivo) :-
    findall(N-G, conteo_genero(G, N), Pares),
    sort(0, @>=, Pares, Orden),
    length(Top, 15),
    append(Top, _, Orden),
    pairs_keys_values(Top, Cuantas, Generos),
    salida('generos.png', Archivo),
    py_call(graficas:barras("Los 15 géneros con más películas", Generos, Cuantas, Archivo,
                            horizontal = true), _).

%! grafica_actor(+Actor, -Archivo) is semidet.
%  Películas por año de un actor. Falla si el actor no está en la base.
grafica_actor(Actor, Archivo) :-
    findall(A-N,
            aggregate(count, Id^T^( actua(Id, Actor), pelicula(Id, T, A) ), N),
            Pares),
    Pares \== [],
    pairs_keys_values(Pares, Anios, Cuantas),
    format(string(Titulo), "Películas por año de ~w", [Actor]),
    salida_de(actor, Actor, Archivo),
    py_call(graficas:barras(Titulo, Anios, Cuantas, Archivo), _).

% --- Grafos con networkx ----------------------------------------------------------

%! red_de(+Actor, -Aristas) is semidet.
%  El actor, sus 12 compañeros más frecuentes y las películas que comparten entre sí.
%  Aristas = [[A, B, Peliculas], ...]: listas, que Python recibe tal cual.
red_de(Actor, Aristas) :-
    companeros(Actor, 12, Cs),
    Cs \== [],
    pairs_values(Cs, Otros),
    findall([Actor, B, N], member(N-B, Cs), Directas),
    findall([A, B, N],
            ( member(A, Otros), member(B, Otros), A @< B,
              aggregate_all(count, coactor(A, B, _), N),
              N > 0 ),
            Entre),
    append(Directas, Entre, Aristas).

%! grafica_red(+Actor, -Archivo) is semidet.
grafica_red(Actor, Archivo) :-
    red_de(Actor, Aristas),
    salida_de(red, Actor, Archivo),
    py_call(graficas:red(Actor, Aristas, Archivo), _).

%! centrales(+Actor, +N, -Lista) is semidet.
%  Python devuelve un resultado y Prolog sigue razonando con él: Lista = [Actor-Puntaje, ...]
centrales(Actor, N, Lista) :-
    red_de(Actor, Aristas),
    py_call(graficas:centrales(Aristas, N), Filas),
    findall(Nombre-P, member([Nombre, P], Filas), Lista).

% --- Archivos de salida -----------------------------------------------------------

salida(Nombre, Archivo) :-
    make_directory_path(salida),
    directory_file_path(salida, Nombre, Archivo).

salida_de(Tipo, Actor, Archivo) :-
    term_hash(Actor, Hash),
    format(atom(Nombre), '~w_~w.png', [Tipo, Hash]),
    salida(Nombre, Archivo).
