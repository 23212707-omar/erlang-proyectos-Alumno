---
tags: [erlang, log]
---

# LOG — Bitacora del repaso

Formato: `## AAAA-MM-DD HH:MM` + que se hizo + proyectos tocados. Lo mas reciente arriba.
Pendientes en [[TODO]].

## 2026-11-02 — Estándares de repositorio público

- Se agregan LICENSE (MIT, elegida por defecto; pendiente de confirmar), README raíz, CITATION.cff, CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, CHANGELOG, `.editorconfig`, `.gitattributes` y `.gitignore` ampliado.
- Se agregan `.github/` con plantillas de issues y PR, Dependabot y CI (compile + eunit; matriz limitada a 4 proyectos, sin ejecutar aún).
- Cambio documental/configuración; no se ejecutó compilación, eunit ni el workflow.

## 2026-10-31 — Registro de eventos y acuerdos

- Se revisa `.claude/`: contiene configuración local y un archivo de bloqueo de tareas; no contiene notas, eventos ni acuerdos que fusionar.
- Se documenta una única bitácora compartida por todos los agentes, con fusión de contenido relacionado sin duplicados.
- Se conserva la bóveda existente y su historial de repaso de los 81 proyectos.
- Se añade [[ACUERDOS]] y se enlazan las tres notas desde el README de la bóveda.
- Se incorpora a `AGENTS.md` la instrucción de registrar eventos, acuerdos y tareas durante el trabajo.
- Cambio exclusivamente documental; sin cambios de código ni ejecución de compilación o eunit.

## 2026-10-27 — Loop 5m
- TODO.md: 81/81 marcados, 0 pendientes. Nada que revisar.
- TERMINADO

## 2026-10-27 — Lotes 4 y 5 (fin)
- Repasados 36-81: README con *Diseno OTP sugerido* en los 81 proyectos.
- Verificacion final de compilacion y eunit sobre las 81 plantillas.

## 2026-10-27 — Lote 3
- Repasados 29-35 (aviacion/transporte e industria).
- Siguiente: 36-42.

## 2026-10-27 — Lote 1 y 2
- Repasados 1-28: README con seccion *Diseno OTP sugerido* (procesos, supervision, API, metricas, caos).
- Siguiente: 29-35 y adelante.

## 2026-10-26 — Plantillas
- Generadas las 81 plantillas en `proyectos/` (rebar.config, app/sup/server, eunit, config, design/PROMPT_STITCH.md).
- Compilan y pasan eunit con `erlc` (sin rebar3 instalado).
- Catalogo en `PROYECTOS.md`, contexto de opencode en `AGENTS.md`.
