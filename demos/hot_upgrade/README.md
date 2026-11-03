# hot_upgrade

Demo de **carga de código en caliente**: se cambia el módulo de un `gen_server` que
sigue corriendo, conservando su pid y su estado. Sin dependencias externas.

## Qué cambia entre versiones

| | v1 (`src/`) | v2 (`priv/versions/`) |
|---|---|---|
| Estado | entero | mapa `#{count, step}` |
| Cada tick | suma 1 | suma `step` (5) |
| Salida | `[v1] cuenta=N` | `[v2] cuenta=N (paso 5)` |

`code_change/3` de la v2 migra el entero de la v1 al mapa. La v2 está en `priv/` para
que `rebar3` no la compile junto con la v1 (comparten nombre de módulo).

## Uso

```bash
rebar3 shell
```

```erlang
1> hot_upgrade_counter:bump().   % la cuenta sube; observa los "[v1] cuenta=..." cada segundo
2> whereis(hot_upgrade_counter). % anota el pid
3> hot_upgrade:upgrade().        % {ok, #{from => 1, to => 2, pid => ...}}
4> whereis(hot_upgrade_counter). % mismo pid; ahora imprime "[v2] ..." y la cuenta continúa
```

## Cómo funciona `hot_upgrade:upgrade/0`

`sys:suspend` → `code:purge` → `code:load_binary` → `sys:change_code` → `sys:resume`.
Es la misma secuencia que ejecuta un *relup* de OTP, pero hecha a mano para verla.

## Para la clase

- Dejar el servicio corriendo en una terminal y hacer el upgrade desde otra
  (`erl -remsh`) para mostrar que no hay reinicio ni pérdida de estado.
- Lo que no se puede hacer así: cambiar la forma del estado sin `code_change/3`.
- En producción esto se empaqueta con `.appup`/`.relup`; aquí es solo didáctico.

## Pruebas

```bash
rebar3 eunit
```
