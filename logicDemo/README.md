# logicDemo — 36 000 películas consultadas con Prolog

Demo de programación lógica sobre una base grande y real: 36 273 películas de 1900 a 2023
con 133 326 créditos de reparto, extraídas de Wikipedia. Todo corre con SWI-Prolog y sus
bibliotecas incluidas: el servidor web, el JSON, la agregación y las pruebas.

![Búsqueda de «matrix» en la página de la demo](design/capturas/buscar.png)

La interfaz se generó en [Google Stitch](https://stitch.withgoogle.com) con este prompt
y después se adaptó a la API real:

```text
Design a responsive web app called "Películas en Prolog": a film explorer over a
database of 36,273 movies (1900–2023) answered by a Prolog logic engine. All UI text in
Spanish. Mobile-first, must look good on a phone and on desktop.

Style: professional, editorial, cinema-inspired. Dark theme: near-black background
(#0f1115), elevated cards (#181b22), warm amber accent (#f5b942) for actions and
highlights, soft off-white text, muted gray secondary text. Typeface: a clean sans
(Inter) for UI and a serif display font for the title and movie names. Rounded 12px
cards, subtle borders, generous spacing, no stock photos, no posters (the data has no
images); use genre chips, year badges and initials avatars for actors instead.

Single page with a sticky top bar (logo text "Películas en Prolog", small tag
"36 273 películas · 133 326 créditos") and a tab bar with four sections:

1. "Buscar" — large search field with placeholder "Busca un título, p. ej. matrix" and
   a "Buscar" button. Results as a grid of movie cards: title (serif), year badge, genre
   chips, cast list truncated to two lines with "ver más", and a secondary button
   "Parecidas". Pressing "Parecidas" shows the ten most similar movies, each with an
   amber score pill like "14 puntos". Include an empty state ("Sin resultados") and a
   loading skeleton.

2. "Actor" — search field with placeholder "Tom Hanks". Result: a profile header with
   initials avatar, name, and three stat tiles ("59 películas", "Desde 1980",
   "Hasta 2023"). Below, a row "Trabajó más con" of actor chips with a count
   ("Tim Allen · 5"), and a vertical timeline of the filmography grouped by year.

3. "Conexión" — two fields "De" and "A" (placeholders "Kevin Bacon", "Zendaya") and a
   button "Conectar". Result: a headline "4 grados de separación" and a horizontal
   chain (vertical on mobile) alternating actor nodes (circles with initials and name)
   and movie connectors (small card with title and year) joined by lines. Error state:
   "Sin camino, o algún actor no existe".

4. "Géneros" — a ranked horizontal bar chart of movies per genre (Drama 14 062,
   Comedy 10 498, Silent 7 131, Western 4 436, Romance 2 857...), bars in amber with the
   count at the end, top 15.

Footer: "La página solo pregunta; todas las respuestas las deduce el servidor Prolog."
and "Datos: Wikipedia".

Plain HTML and CSS only, no JavaScript frameworks. Accessible contrast, visible focus
states, minimum 44px touch targets.
```

El tutorial va de la instalación a las consultas con backtracking, el análisis de la base
y el servidor web.

| Archivo | Qué hace |
|---|---|
| `descargar.sh` | Baja el JSON y lanza la importación. |
| `importar.pl` | Convierte el JSON en hechos Prolog (`datos/peliculas.pl`). |
| `consultas.pl` | Las reglas: búsqueda, agregación, recomendación y grafo de actores. |
| `servidor.pl` | Servidor HTTP con API JSON y la página. |
| `web/index.html` | Página que solo pregunta al servidor. |
| `pruebas.pl` | Pruebas con plunit. |

## 1. Instalación

Ubuntu, o Windows con WSL (la PPA trae la versión estable reciente):

```bash
sudo apt-add-repository ppa:swi-prolog/stable
sudo apt update && sudo apt install swi-prolog curl
```

macOS:

```bash
brew install swi-prolog
```

Comprueba con `swipl --version`. La demo se probó con la versión 10.0.2.

## 2. Cargar los datos

```bash
./descargar.sh
```

Baja `datos/movies.json` (25 MB) de
[prust/wikipedia-movie-data](https://github.com/prust/wikipedia-movie-data) y genera
`datos/peliculas.pl`. La carpeta `datos/` no se sube al repositorio.

Cada película del JSON se reparte en cuatro relaciones:

```prolog
pelicula(30077, "The Matrix", 1999).
actua(30077, 'Keanu Reeves').
genero(30077, 'Science Fiction').
sinopsis(30077, "The Matrix is a 1999 science fiction action film...").
```

> **Hecho:** una afirmación que se da por cierta. La base de datos es el conjunto de
> hechos; no hay tablas ni esquema aparte.

`importar.pl` usa `json_read_dict/2` para leer el JSON como diccionarios y `format/3` con
`~q` para escribir términos que Prolog puede volver a leer.

## 3. Primeras consultas

```bash
swipl consultas.pl
```

```prolog
?- pelicula(Id, "The Matrix", Anio).
Id = 30077, Anio = 1999.

?- actua(30077, Quien).
Quien = 'Keanu Reeves' ;
Quien = 'Laurence Fishburne' ;
Quien = 'Carrie-Anne Moss' ;
Quien = 'Hugo Weaving'.
```

Con `;` pides la siguiente respuesta; con Enter te quedas con la actual.

> **Unificación:** Prolog busca valores para las variables (empiezan con mayúscula) que
> hagan coincidir la consulta con un hecho.
>
> **Backtracking:** cuando pides otra respuesta, o cuando un paso falla, Prolog regresa
> al último punto donde había alternativas y prueba la siguiente.

La misma relación contesta la pregunta inversa, sin escribir nada nuevo:

```prolog
?- actua(Id, 'Keanu Reeves'), pelicula(Id, Titulo, Anio).
```

La coma es un «y». Esta consulta es un *join*: por cada película de Keanu Reeves, busca
su título y su año.

## 4. Reglas

Una regla pone nombre a una consulta. De `consultas.pl`:

```prolog
coactor(A, B, Id) :-
    actua(Id, A),
    actua(Id, B),
    A \== B.
```

Se lee «A y B son coactores en Id si los dos actúan en Id y no son la misma persona».
Sirve en cualquier dirección:

```prolog
?- coactor('Kevin Bacon', Quien, Id).              % con quién trabajó
?- coactor('Kevin Bacon', 'Meryl Streep', Id).     % en qué película coincidieron
?- coactor(A, B, 30077).                           % todas las parejas de The Matrix
```

Otras reglas del archivo:

```prolog
?- titulo_contiene(godfather, Id, Titulo, Anio).   % búsqueda sin distinguir mayúsculas
?- nueva_version(Titulo, Anio1, Anio2).            % mismo título, años distintos
?- filmografia('Tom Hanks', Lista).
```

`nueva_version/3` es un auto-join: la tabla `pelicula` contra sí misma. Pide varias
respuestas con `;` para ver el backtracking recorrer la base.

## 5. Juntar todas las respuestas

El backtracking da una respuesta a la vez. Para tenerlas en una lista:

```prolog
?- findall(Titulo, titulo_contiene(matrix, _, Titulo, _), Lista).
Lista = ["The Matrix", "The Matrix Reloaded", "The Matrix Revolutions", ...].
```

Para ver solo algunas, o en orden (`library(solution_sequences)`):

```prolog
?- limit(5, titulo_contiene(star, _, T, A)).
?- order_by([desc(A)], titulo_contiene(star, _, T, A)).
```

## 6. Negación y «para todos»

```prolog
?- sin_reparto(Id), pelicula(Id, Titulo, Anio).
```

`sin_reparto/1` usa `\+`, la negación por falla.

> **Negación por falla:** `\+ actua(Id, _)` es cierto cuando Prolog no puede demostrar
> que alguien actúa en la película. Significa «no consta», no «es falso»: 869 películas
> de la base no tienen reparto registrado, y eso no quiere decir que no lo tuvieran.

`forall/2` expresa «para todos»:

```prolog
?- solo_genero('Gene Autry', Genero).    % ¿todas sus películas son de un mismo género?
Genero = 'Western'.                      % las 85
```

## 7. Análisis de la base

`library(aggregate)` hace el trabajo de `COUNT`, `MIN`, `MAX` y `GROUP BY`:

```prolog
?- aggregate_all(count, pelicula(_, _, _), N).
N = 36273.

?- conteo_genero(Genero, N).                 % un género por respuesta, como GROUP BY
?- order_by([desc(N)], conteo_genero(G, N)).
G = 'Drama', N = 14062 ;
G = 'Comedy', N = 10498 ;
G = 'Silent', N = 7131 ...

?- mas_activos(5, Lista).
Lista = [190-'Harold Lloyd', 157-'Hoot Gibson', 137-'Charles Starrett', ...].

?- carrera('Tom Hanks', Primer, Ultimo, Cuantas).
Primer = 1980, Ultimo = 2023, Cuantas = 59.

?- companeros('Tom Hanks', 3, Lista).
Lista = [5-'Tim Allen', 3-'Annie Potts', 3-'Bonnie Hunt'].
```

Películas por década, escrita directo en la consola:

```prolog
?- aggregate(count, Id^decada(Id, Decada), N).
```

`Id^` indica que `Id` no agrupa; la variable que queda libre (`Decada`) es la clave del
grupo.

## 8. Recomendación

Dos cláusulas declaran qué hace parecidas a dos películas, y la agregación suma los
puntos:

```prolog
afinidad(Id, Otra, 3) :- actua(Id, A), actua(Otra, A), Otra \== Id.
afinidad(Id, Otra, 1) :- genero(Id, G), genero(Otra, G), Otra \== Id.
```

```prolog
?- similares(30077, 5, Lista).
Lista = [14-30999, 14-31000, ...].      % las dos secuelas de The Matrix, primero
```

Cambiar el criterio es cambiar o agregar una cláusula; el resto no se toca.

## 9. El grafo de actores

Dos actores están conectados si compartieron película. `camino/3` busca la cadena más
corta entre dos, el «número de Bacon»:

```prolog
?- camino('Buster Keaton', 'Zendaya', Camino).
Camino = ['Buster Keaton',
          paso("A Funny Thing Happened on the Way to the Forum", 1966),
          'Michael Hordern', paso("Ivanhoe", 1982),
          'Sam Neill',       paso("Peter Rabbit", 2018),
          'James Corden',    paso("Smallfoot", 2018),
          'Zendaya'].
```

> **Recursión:** `bfs/5` se llama a sí misma con la siguiente capa de actores hasta
> encontrar el destino. Es búsqueda en anchura: por eso el primer camino hallado es el
> más corto.

Los actores ya visitados se guardan en un árbol balanceado (`library(assoc)`), junto con
la película por la que se llegó a cada uno; con eso se reconstruye el camino al final.

## 10. Rendimiento

```prolog
?- time(camino('Buster Keaton', 'Zendaya', _)).
?- jiti_list(consultas:actua/2).
```

> **Indexado:** SWI-Prolog crea índices sobre los argumentos según las consultas que
> recibe (indexado «justo a tiempo»). Por eso `actua(Id, 'Tom Hanks')` no recorre los
> 133 326 hechos, aunque el actor sea el segundo argumento. `jiti_list/1` muestra los
> índices creados.

Los actores y géneros se guardan como átomos (`'Tom Hanks'`), que se comparan y se
indexan más rápido que las cadenas (`"The Matrix"`).

Otras herramientas del sistema que vale la pena probar aquí: `trace.` para ver el
backtracking paso a paso, `gtrace.` para el depurador gráfico y `profile(Consulta)` para
ver dónde se va el tiempo.

## 11. Servidor web

```bash
swipl servidor.pl          # http://localhost:8080/
swipl servidor.pl 9000     # otro puerto
```

| Ruta | Responde |
|---|---|
| `/` | La página. |
| `/api/buscar?q=matrix` | Películas cuyo título contiene el texto (hasta 50). |
| `/api/actor?nombre=Tom Hanks` | Carrera, filmografía y compañeros frecuentes. |
| `/api/camino?de=Kevin Bacon&a=Zendaya` | Camino más corto entre dos actores. |
| `/api/similares?id=30077` | Las diez películas más afines. |
| `/api/generos` | Conteo por género. |

```bash
curl "localhost:8080/api/camino?de=Kevin+Bacon&a=Meryl+Streep"
```

Bibliotecas usadas, todas incluidas en SWI-Prolog:

| Biblioteca | Para qué |
|---|---|
| `http/thread_httpd` | El servidor, con un hilo por petición. |
| `http/http_dispatch` | Asociar rutas a predicados (`http_handler/3`). |
| `http/http_parameters` | Leer y validar los parámetros de la URL. |
| `http/http_json` | Responder JSON (`reply_json_dict/1`). |
| `http/json` | Leer el JSON de origen. |
| `aggregate`, `solution_sequences` | Conteos, agrupación, orden y límite. |
| `assoc` | Árbol balanceado para la búsqueda en el grafo. |
| `yall` | Lambdas (`[X, Y]>>...`) con `maplist/3`. |
| `plunit` | Pruebas. |

La página se diseñó en Google Stitch (prompt en `design/PROMPT_STITCH.md`) y se adaptó a
la API real. Carga Tailwind y las fuentes desde internet, así que el navegador necesita
conexión para verla con estilo.

El servidor no contiene reglas: cada ruta llama a un predicado de `consultas.pl` y
convierte la respuesta a JSON. La página tampoco decide nada.

## 12. Pruebas

```bash
swipl -g run_tests -t halt pruebas.pl
```

Son ocho pruebas sobre la base cargada.

## Para seguir

- Escribe `director/2` a partir de otra fuente y pregunta qué actores repiten con un
  mismo director.
- Añade una tercera cláusula a `afinidad/3` (misma década, por ejemplo) y mira cómo
  cambian las recomendaciones.
- Cambia el límite de seis saltos en `camino/3` y busca la pareja de actores más lejana
  que encuentres.
- Marca `camino/3` con `time/1` antes y después de cambiar `library(assoc)` por una
  lista: ahí se ve por qué importa la estructura de datos.

## Datos

Los datos vienen de Wikipedia a través de
[prust/wikipedia-movie-data](https://github.com/prust/wikipedia-movie-data). Algunos
créditos traen ruido del origen, como `(voices)` o `voices of` en el reparto; la demo no
los limpia.
