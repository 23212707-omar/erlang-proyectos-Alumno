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
| [`demos/`](demos/) | Demos de clase (p. ej. [Cowboy: REST, SSE, WebSocket](demos/cowboy_demo/)) |
| [`PROYECTOS.md`](PROYECTOS.md) | Catálogo, roles del equipo y niveles sugeridos |
| [`exposicion/`](exposicion/) | Diapositivas de la exposición |
| [`bitacora/`](bitacora/) | Bitácora (Obsidian): eventos, acuerdos y tareas |
| [`AGENTS.md`](AGENTS.md) | Convenciones técnicas y flujo de trabajo |

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
Detalles y convenciones en [`AGENTS.md`](AGENTS.md).

## Contribuir

Lee [`CONTRIBUTING.md`](CONTRIBUTING.md) y el [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
Para vulnerabilidades, ver [`SECURITY.md`](SECURITY.md).

## Cómo citar

Ver [`CITATION.cff`](CITATION.cff) (GitHub muestra el botón *Cite this repository*).

## Licencia

[MIT](LICENSE) © 2026 René Solis R. y colaboradores.
