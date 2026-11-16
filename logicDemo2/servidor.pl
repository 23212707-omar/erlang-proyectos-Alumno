% Servidor web: Prolog recibe la petición, deduce los datos, pide la imagen a Python
% y la devuelve.
% Uso: swipl servidor.pl            (puerto 8081)
%      swipl servidor.pl 9000

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).
:- use_module(analisis).

:- initialization(main, main).

:- http_handler(root(.),                  inicio,    []).
:- http_handler(root('grafica/decadas'),  g_decadas, []).
:- http_handler(root('grafica/generos'),  g_generos, []).
:- http_handler(root('grafica/actor'),    g_actor,   []).
:- http_handler(root('grafica/red'),      g_red,     []).

main(Argv) :-
    (   Argv = [A|_], atom_number(A, Puerto) -> true ; Puerto = 8081 ),
    http_server(http_dispatch, [port(Puerto)]),
    format("Demo en http://localhost:~w/~n", [Puerto]),
    thread_get_message(_).

% La página se escribe con html_write: HTML como términos Prolog.
inicio(Peticion) :-
    http_parameters(Peticion, [actor(Actor, [default('Tom Hanks')])]),
    reply_html_page(
        [ title('Películas en Prolog + Python'),
          meta([name(viewport), content('width=device-width, initial-scale=1')]),
          style('body{font:16px system-ui;background:#111317;color:#e2e2e8;max-width:920px;
                 margin:0 auto;padding:16px} img{max-width:100%;border-radius:12px;margin:8px 0}
                 input,button{font:inherit;padding:8px} h1,h2{font-family:Georgia,serif}')
        ],
        [ h1('Películas en Prolog + Python'),
          p('Prolog deduce los datos; Python (matplotlib y networkx) solo los dibuja.'),
          form([action('/')],
               [ input([name(actor), value(Actor)]), ' ',
                 button('Ver actor')
               ]),
          h2(Actor),
          img([src('/grafica/actor?nombre=' + encode(Actor)), alt('Películas por año')]),
          img([src('/grafica/red?nombre=' + encode(Actor)), alt('Red de colaboraciones')]),
          h2('Toda la base'),
          img([src('/grafica/decadas'), alt('Películas por década')]),
          img([src('/grafica/generos'), alt('Géneros')])
        ]).

g_decadas(Peticion) :- grafica_decadas(Archivo), imagen(Archivo, Peticion).
g_generos(Peticion) :- grafica_generos(Archivo), imagen(Archivo, Peticion).

g_actor(Peticion) :-
    http_parameters(Peticion, [nombre(Actor, [])]),
    (   grafica_actor(Actor, Archivo)
    ->  imagen(Archivo, Peticion)
    ;   http_404([], Peticion)
    ).

g_red(Peticion) :-
    http_parameters(Peticion, [nombre(Actor, [])]),
    (   grafica_red(Actor, Archivo)
    ->  imagen(Archivo, Peticion)
    ;   http_404([], Peticion)
    ).

imagen(Archivo, Peticion) :-
    http_reply_file(Archivo, [unsafe(true), cache(false)], Peticion).
