# let_it_crash

Demo de **supervisión**: se mata un proceso a propósito y se ve quién lo reinicia y a
quién arrastra. Sin dependencias externas (solo OTP).

## Árbol de supervisión

```
let_it_crash_sup (rest_for_one)
├── let_it_crash_store         dueño de la tabla ETS con la última lectura de cada sensor
├── let_it_crash_agg           promedio de los sensores (depende del store)
└── let_it_crash_sensors_sup (one_for_one)
    ├── sensor_a
    ├── sensor_b
    └── sensor_c
```

- **one_for_one** (sensores): son independientes; si muere `sensor_a` solo se reinicia él.
- **rest_for_one** (raíz): `agg` y los sensores dependen del store; si muere el store se
  reinicia todo lo que se arrancó después.
- Los sensores no tienen `try/catch`: dejar que falle y que el supervisor decida es la idea.

## Uso

```bash
rebar3 shell
```

```erlang
1> let_it_crash:run().          % guion completo: mata un sensor y luego el store
2> let_it_crash:tree().         % pids actuales
3> let_it_crash:kill(sensor_b). % matar a mano
```

Con `rebar3 shell` se ven en pantalla los reportes de crash y reinicio.

## Para la clase

1. Matar un sensor y comparar pids antes/después.
2. Matar el store y ver que se reinician `agg` y los tres sensores.
3. Preguntar: ¿qué pasaría con `one_for_one` en la raíz? (los sensores seguirían con una
   tabla ETS que ya no existe y fallarían en cadena).
4. Matar procesos en bucle hasta superar `intensity`: el supervisor se rinde y escala el fallo.

## Pruebas

```bash
rebar3 eunit
```
