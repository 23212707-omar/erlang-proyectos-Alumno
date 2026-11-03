# erlang-proyectos

[![CI](https://github.com/tectijuana/erlang-proyectos/actions/workflows/ci.yml/badge.svg)](https://github.com/tectijuana/erlang-proyectos/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Erlang/OTP 27](https://img.shields.io/badge/Erlang%2FOTP-27-a90533.svg)

Catálogo y esqueletos de 81 proyectos de estudiantes en **Erlang/OTP** (TecNM, Instituto
Tecnológico de Tijuana), pensados para desplegarse en un Raspberry Pi Compute Module 5
(aarch64, Debian 13) pero desarrollables en macOS/Linux.

## Contenido

| Ruta | Descripción |
|---|---|
| [`proyectos/`](proyectos/) | 81 proyectos (`NN-nombre/`), cada uno una aplicación OTP con `rebar.config`, `src/`, `test/` y `README.md` |
| [`demos/`](demos/) | Demos de clase: Cowboy, supervisión, código en caliente y behaviours |
| [`PROYECTOS.md`](PROYECTOS.md) | Catálogo, roles del equipo y niveles sugeridos |
| [`exposicion/`](exposicion/) | Diapositivas de la exposición |

## Catálogo de proyectos

Detalle de cada tema, roles del equipo y niveles en [`PROYECTOS.md`](PROYECTOS.md).

| # | Categoría | Proyectos |
|---|---|---|
| 1–5 | Agro e IoT | 5 |
| 6–9 | Ciudad y edificios | 4 |
| 10–14 | Servicios web y datos | 5 |
| 15–18 | Sistemas distribuidos | 4 |
| 19–21 | Operación y calidad | 3 |
| 22–31 | Aviación y transporte | 10 |
| 32–38 | Industria y manufactura | 7 |
| 39–44 | Salud | 6 |
| 45–51 | Educación y campus | 7 |
| 52–58 | Energía y medio ambiente | 7 |
| 59–66 | Comercio, finanzas y servicios | 8 |
| 67–71 | Seguridad y ciudad | 5 |
| 72–76 | Entretenimiento y juegos | 5 |
| 77–81 | Agro y alimentos | 5 |

Cada proyecto es independiente y contiene: `src/` (aplicación OTP con supervisor y
`gen_server`), `test/` (eunit), `config/` (`sys.config`, `vm.args`), `design/` (prompt
y diseño de la UI en Google Stitch) y `problema/`.

## Arquitectura de referencia

- Árbol de supervisión por proyecto (`one_for_one` / `rest_for_one`), un proceso por entidad del dominio.
- HTTP con **cowboy** (estáticos, JSON bajo `/api/...`, WebSocket/SSE); métricas en `/metrics`.
- Diagnóstico remoto con **recon**; sin `observer` en el nodo desplegado.
- `vm.args` de referencia para el CM5: `+S 4:4 +SDcpu 4:4 +SDio 10 +K true +P 1048576`.

## Requisitos

- Erlang/OTP 27 y [rebar3](https://rebar3.org/) 3.28 (recomendado: [asdf](https://asdf-vm.com/))

## Uso rápido

```bash
cd proyectos/01-vinedos
rebar3 compile
rebar3 eunit
rebar3 shell
```

## Stack

cowboy 2.x · recon · prometheus.erl · PostgreSQL (epgsql + poolboy) · releases con relx.
Convenciones en [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Contribuir

Lee [`CONTRIBUTING.md`](CONTRIBUTING.md) y el [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
Para vulnerabilidades, ver [`SECURITY.md`](SECURITY.md).

## Cómo citar

Ver [`CITATION.cff`](CITATION.cff) (GitHub muestra el botón *Cite this repository*).

## Licencia

[MIT](LICENSE) © 2026 René Solis R. y colaboradores.
