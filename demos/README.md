# demos

Proyectos de demostración usados en clase. Cada uno vive en su propia carpeta.

| Demo | Qué muestra |
|---|---|
| [cowboy_demo](cowboy_demo/) | Cowboy: REST, SSE, WebSocket y estáticos sobre un árbol de supervisión |
| [let_it_crash](let_it_crash/) | Supervisión: `one_for_one` vs `rest_for_one` matando procesos en vivo |
| [hot_upgrade](hot_upgrade/) | Carga de código en caliente conservando pid y estado |
| [plugin_sinks](plugin_sinks/) | Modularidad con behaviours: salidas intercambiables en caliente |

`let_it_crash`, `hot_upgrade` y `plugin_sinks` no tienen dependencias externas (solo OTP).
