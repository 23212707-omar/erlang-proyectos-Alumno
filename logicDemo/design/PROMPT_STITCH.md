# Prompt para Google Stitch — logicDemo

Pegar en [stitch.withgoogle.com](https://stitch.withgoogle.com), modo web. Al terminar,
exportar el zip (HTML/CSS, capturas y `DESIGN.md`) a esta carpeta `design/`.

## Prompt

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

## Datos que la página recibe

La interfaz debe poder pintarse solo con esto (ver `servidor.pl`):

| Ruta | Campos |
|---|---|
| `/api/buscar?q=` | lista de `{id, titulo, anio, generos[], reparto[]}` |
| `/api/similares?id=` | igual que buscar, más `puntos` |
| `/api/actor?nombre=` | `{actor, primer, ultimo, peliculas, filmografia[{anio, titulo}], companeros[{actor, veces}]}` |
| `/api/camino?de=&a=` | `{grados, camino[{actor} o {pelicula, anio}]}` |
| `/api/generos` | lista de `{genero, peliculas}` |
