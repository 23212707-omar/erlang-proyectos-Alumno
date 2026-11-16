#!/bin/sh
# Descarga el conjunto de datos (unas 36 000 películas, 25 MB) y lo convierte a hechos Prolog.
# Fuente: https://github.com/prust/wikipedia-movie-data (datos extraídos de Wikipedia).
set -e
cd "$(dirname "$0")"
mkdir -p datos
[ -f datos/movies.json ] || curl -L -o datos/movies.json \
  https://raw.githubusercontent.com/prust/wikipedia-movie-data/master/movies.json
swipl importar.pl
