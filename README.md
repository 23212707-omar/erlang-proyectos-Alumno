# Programación Lógica y Funcional

**Tecnológico Nacional de México · Instituto Tecnológico de Tijuana**

[![CI](https://github.com/tectijuana/logicfun-proyectos/actions/workflows/ci.yml/badge.svg)](https://github.com/tectijuana/logicfun-proyectos/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Erlang/OTP 27](https://img.shields.io/badge/Erlang%2FOTP-27-a90533.svg)
![SWI-Prolog](https://img.shields.io/badge/SWI--Prolog-10-e61b23.svg)

## Bienvenida

Te damos la bienvenida al repositorio del curso. Aquí está el material con el que vas a
trabajar: 81 proyectos tomados de problemas reales (viñedos, estacionamientos, cadena de
frío, hospitales, aeropuertos), las demos de clase y los retos de cada proyecto.

El curso recorre dos formas de programar que casi nunca se ven en otras materias, y las
dos se aplican sobre el mismo proyecto:

| Fase | Paradigma | Lenguaje | Qué construyes |
|---|---|---|---|
| 1 | Funcional y concurrente | Erlang/OTP | Un sistema que no se cae: procesos supervisados, mensajes y tolerancia a fallas. |
| 2 | Lógico | SWI-Prolog | El **gemelo digital** del mismo proyecto: un modelo que razona con reglas, decide y explica por qué. |

En Erlang el sistema *hace* cosas. En Prolog el gemelo *deduce*: contesta preguntas que
ningún dato trae escrito, como si una hilera del viñedo está en riesgo o a quién se le
entrega la última unidad de un producto.

## Por dónde empezar

1. Clona el repositorio:

   ```bash
   git clone https://github.com/tectijuana/logicfun-proyectos.git
   cd logicfun-proyectos
   ```

2. Ubica tu proyecto en [`PROYECTOS.md`](PROYECTOS.md) y abre su carpeta en
   `proyectos/NN-nombre/`.
3. Lee `problema/readme.md`: es el planteamiento original, el punto de partida de todo.
4. Para la fase de Prolog, lee `gemelo/PROBLEMA.md`. Trae las cinco situaciones que tu
   gemelo debe razonar.
5. Antes de escribir tu gemelo, corre la demo [`logicDemo/`](logicDemo/). Su tutorial te
   lleva de la instalación de SWI-Prolog a las consultas con backtracking y al servidor
   web.

## Qué hay en el repositorio

| Ruta | Descripción |
|---|---|
| [`proyectos/`](proyectos/) | Los 81 proyectos (`NN-nombre/`), cada uno con su aplicación OTP y su reto de gemelo digital. |
| [`PROYECTOS.md`](PROYECTOS.md) | Catálogo de temas, roles del equipo y niveles sugeridos. |
| [`demos/`](demos/) | Demos de Erlang: Cowboy, supervisión, código en caliente y behaviours. |
| [`logicDemo/`](logicDemo/) | Demo de Prolog: 36 000 películas consultadas con SWI-Prolog, con servidor web y tutorial. |
| [`exposicion/`](exposicion/) | Diapositivas de la exposición. |

Dentro de cada proyecto:

| Carpeta | Contenido |
|---|---|
| `problema/` | Planteamiento original del problema. |
| `src/`, `test/`, `config/` | Aplicación OTP (supervisor y `gen_server`), pruebas eunit, `sys.config` y `vm.args`. |
| `design/` | Prompt y diseño de la interfaz en Google Stitch. |
| `gemelo/PROBLEMA.md` | El reto de Prolog: escenario, situaciones y lo que entregas. |
| `gemelo/CONTEXTO_AGENTES.md` | Contexto del dominio para tu asistente de IA. |

## Fase 1 — Erlang/OTP

```bash
cd proyectos/01-vinedos
rebar3 compile
rebar3 eunit
rebar3 shell
```

Necesitas Erlang/OTP 27 y [rebar3](https://rebar3.org/) 3.28; lo más cómodo es instalarlos
con [asdf](https://asdf-vm.com/).

- Cada proyecto tiene un árbol de supervisión, con un proceso por entidad del dominio.
- La interfaz se sirve con **cowboy**: archivos estáticos, JSON bajo `/api/...` y tiempo
  real por WebSocket o SSE.
- Los proyectos están pensados para un Raspberry Pi Compute Module 5 (aarch64, Debian 13),
  pero se desarrollan igual en macOS, Linux o Windows con WSL.

Stack: cowboy 2.x · recon · prometheus.erl · PostgreSQL (epgsql + poolboy) · releases con
relx.

## Fase 2 — Gemelo digital en Prolog

Tu gemelo es un programa en SWI-Prolog con hechos, reglas y su propio servidor web. Debe
contestar, con las mismas reglas, preguntas de decisión, de explicación y de hipótesis
(«¿qué pasaría si…?»).

```bash
# Ubuntu o Windows con WSL
sudo apt-add-repository ppa:swi-prolog/stable
sudo apt update && sudo apt install swi-prolog
```

- El reto no trae la solución: la construyes tú. Las situaciones de `PROBLEMA.md` te dicen
  qué debe deducir el gemelo, no cómo.
- Prolog es el programa, no un accesorio. Python es opcional y solo llamado **desde**
  Prolog (Janus), por ejemplo para graficar.
- La interfaz se diseña en Google Stitch y solo pregunta al gemelo; ninguna regla vive en
  la página.

## Cómo se trabaja

- **Con asistente de IA, y entendiendo lo que entregas.** El repositorio está preparado
  para trabajar con OpenCode: [`AGENTS.md`](AGENTS.md) y el `CONTEXTO_AGENTES.md` de tu
  proyecto le dan el contexto. El asistente ayuda; quien explica y defiende el trabajo
  eres tú.
- **Diseña antes de programar.** Toda parte visual pasa primero por
  [Google Stitch](https://stitch.withgoogle.com) y se guarda en `design/`.
- **Pruebas siempre.** `rebar3 eunit` en Erlang y plunit en Prolog, al menos una prueba
  por situación del gemelo.
- **Sin secretos en el repositorio.** Nada de contraseñas, cookies ni certificados reales;
  usa valores de ejemplo.
- **Declara tus supuestos.** Si una cifra o una regla no viene del planteamiento original,
  dilo en tu entrega.

## Catálogo de proyectos

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

El detalle de cada tema está en [`PROYECTOS.md`](PROYECTOS.md).

## Contribuir

Las correcciones y mejoras son bienvenidas. Lee [`CONTRIBUTING.md`](CONTRIBUTING.md) y el
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Para reportar una vulnerabilidad, consulta
[`SECURITY.md`](SECURITY.md).

## Cómo citar

Ver [`CITATION.cff`](CITATION.cff); GitHub muestra el botón *Cite this repository*.

## Licencia

[MIT](LICENSE) © 2026 René Solis R. y colaboradores.
