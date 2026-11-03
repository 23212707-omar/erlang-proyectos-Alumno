# plugin_sinks

Demo de **modularidad con behaviours**: un sensor publica lecturas y las salidas
(*sinks*) son módulos intercambiables que se agregan y quitan en caliente. Sin
dependencias externas.

## Diseño

```
plugin_sinks_sup (rest_for_one)
├── pg                       grupo `plugin_sinks_readings`
├── plugin_sinks_sink_sup    simple_one_for_one: un worker por salida
│   └── plugin_sinks_worker  envoltorio genérico (llama a Mod:init/write/terminate)
└── plugin_sinks_sensor      publica {reading, R} al grupo cada segundo
```

El contrato es el behaviour [`plugin_sinks_sink`](src/plugin_sinks_sink.erl):
`init/1`, `write/2` y `terminate/2` (opcional). Salidas incluidas:

| Módulo | Qué hace |
|---|---|
| `plugin_sinks_console` | imprime en pantalla |
| `plugin_sinks_memory` | guarda las últimas N lecturas |
| `plugin_sinks_file` | una línea CSV por lectura (`#{path => "..."}`) |
| `plugin_sinks_flaky` | falla cada 3 escrituras, a propósito |

El sensor no sabe cuántas salidas existen. Las iniciales salen de `sinks` en el `env`.

## Uso

```bash
rebar3 shell
```

```erlang
1> plugin_sinks:sinks().
2> {ok, F} = plugin_sinks:add_sink(plugin_sinks_file, #{path => "/tmp/lecturas.csv"}).
3> {ok, X} = plugin_sinks:add_sink(plugin_sinks_flaky, #{}).   % ve cómo se reinicia solo él
4> plugin_sinks:remove_sink(X).
5> plugin_sinks:add_sink(lists, #{}).                          % {error, {not_a_sink, lists}}
```

## Ejercicio para estudiantes

Escribir `plugin_sinks_postgres` (epgsql + poolboy) o `plugin_sinks_mqtt` implementando
el behaviour, sin modificar `plugin_sinks_sensor`. Si hay que tocar el sensor, el diseño
quedó mal acoplado.

## Pruebas

```bash
rebar3 eunit
```
