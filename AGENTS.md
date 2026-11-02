# Proyectos Erlang/OTP — contexto para opencode

## Registro de trabajo en Obsidian

- Mantén la bóveda `bitacora/` actualizada al realizar trabajo en este repositorio.
- Usa esta única bitácora para todos los agentes (Codex, Claude u opencode).
  Antes de crear notas, revisa las existentes y fusiona contenido relacionado sin
  duplicar eventos, acuerdos ni tareas; conserva fechas, contexto e historial.
- Registra eventos, cambios y resultados de verificaciones en `bitacora/LOG.md`,
  con fecha y entradas nuevas arriba; conserva el historial.
- Registra los acuerdos explícitos con el usuario en `bitacora/ACUERDOS.md`,
  con fecha y contexto. Distingue propuestas pendientes de acuerdos confirmados.
- Mantén tareas y seguimientos en `bitacora/TODO.md` con casillas Markdown;
  marca como completado solo lo que se haya realizado y verificado.
- No inventes responsables, fechas límite, acuerdos ni resultados de pruebas.

Este repositorio contiene proyectos de estudiantes en Erlang/OTP. Los proyectos se
despliegan (o simulan) en un Raspberry Pi Compute Module 5; el desarrollo puede
ocurrir en otra maquina (macOS/Linux), asi que no asumas hardware en el codigo.

## Entorno objetivo

- Hardware: ARM Cortex-A76 x4, 8 GB RAM, aarch64 (RAM para la app ~5.5 GB)
- OS: Debian 13 (Trixie)
- Erlang/OTP 27.3.4.19 con JIT nativo (`emu_flavor = jit`), instalado con asdf
- Build: rebar3 3.28.0 + relx (releases)
- Sin GPU: observer solo en modo remoto

## Stack

- HTTP: cowboy 2.x con ranch
- Diagnostico: recon (NO observer en el nodo de produccion)
- Metricas: prometheus.erl con endpoint `/metrics`
- DB: PostgreSQL via epgsql, pool con poolboy
- NO usar Mnesia como base de datos principal

## vm.args de referencia

```
+S 4:4  +SDcpu 4:4  +SDio 10  +K true
+P 1048576  +Q 65536  +e 204800
+zdbbl 65536  +A 16  +hmqd off_heap
```

Nunca `+S` mayor al numero de cores fisicos (4 en el CM5).

## Convenciones de codigo

- Usa behaviours OTP completos (gen_server, gen_statem, supervisor) en vez de modulos
  sueltos; gen_server antes que `spawn` directo.
- Todo proceso expone `start_link/0` (o `/N`) y cuelga de un arbol de supervision.
  `one_for_one` para workers independientes, `rest_for_one` si hay dependencias de orden.
- Pattern matching exhaustivo; sin clausulas catch-all en funciones criticas.
- Maps en vez de records para estructuras que evolucionan.
- Logs con `logger:info/2`, `logger:error/2` y metadata como map.
- Comentarios explican el "por que", no el "que".
- Tests: eunit para unitarios, common_test para integracion.

## Comandos

```bash
rebar3 compile
rebar3 eunit
rebar3 ct
rebar3 dialyzer
rebar3 shell
rebar3 release     # _build/prod/rel/
```

Antes de dar una tarea por terminada: `rebar3 compile` y `rebar3 eunit` deben pasar.

## Interfaz con Google Stitch

Todo proyecto con parte visual (dashboard, panel de control, app web) disena su UI en
Google Stitch (stitch.withgoogle.com) antes de programarla.

- Flujo: prompt en Stitch -> iterar pantallas -> exportar (zip con HTML/CSS, capturas y
  `DESIGN.md`) -> copiar a `<proyecto>/design/` -> pedir a opencode que lo implemente.
- `design/DESIGN.md` es la fuente de verdad de colores, tipografia, espaciado y
  componentes. Leelo antes de tocar HTML/CSS y no inventes estilos que no esten ahi.
- El backend Erlang solo sirve la UI y datos: archivos estaticos con `cowboy_static`,
  JSON bajo `/api/...` y tiempo real por WebSocket o SSE de cowboy. Sin frameworks JS
  pesados; HTML/CSS/JS plano basta, y la UI debe verse bien en pantalla de celular.
- Si cambia el diseno, se re-exporta desde Stitch y se actualiza `design/`; no se edita
  a mano el HTML exportado sin documentarlo en el README del proyecto.
- Entrega: capturas de las pantallas de Stitch junto con capturas de la app real.

## Forma de trabajo con opencode

- Crea cada proyecto en su propia carpeta (`rebar3 new release <nombre>` o
  `rebar3 new app <nombre>`); no mezcles proyectos.
- Explica brevemente el diseno OTP (arbol de supervision, quien reinicia a quien) antes
  de escribir codigo grande.
- No agregues dependencias fuera del stack sin que el estudiante lo apruebe.
- No pongas cookies, passwords ni certificados reales en el repo; usa `sys.config` o
  variables de entorno con valores de ejemplo.
