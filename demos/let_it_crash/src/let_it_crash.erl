%% API para la clase: let_it_crash:run() ejecuta el guion completo.
-module(let_it_crash).

-export([run/0, snapshot/0, tree/0, kill/1, changed/2]).

%% Mapa nombre => pid de cada proceso supervisado.
-spec snapshot() -> #{atom() => pid() | undefined}.
snapshot() ->
    Names = [let_it_crash_store, let_it_crash_agg, let_it_crash_sensors_sup,
             sensor_a, sensor_b, sensor_c],
    maps:from_list([{N, whereis(N)} || N <- Names]).

tree() ->
    Snap = snapshot(),
    lists:foreach(
      fun(N) -> io:format("  ~-26s ~p~n", [N, maps:get(N, Snap)]) end,
      [let_it_crash_store, let_it_crash_agg, let_it_crash_sensors_sup,
       sensor_a, sensor_b, sensor_c]).

kill(Name) when is_atom(Name) ->
    case whereis(Name) of
        undefined -> {error, not_running};
        Pid ->
            io:format(">> exit(~p, kill)  [~p]~n", [Pid, Name]),
            exit(Pid, kill),
            ok
    end.

%% Nombres cuyo pid cambio entre dos fotos, es decir, los que se reiniciaron.
-spec changed(map(), map()) -> [atom()].
changed(Before, After) ->
    lists:sort([N || {N, Pid} <- maps:to_list(Before), maps:get(N, After) =/= Pid]).

run() ->
    io:format("~n== Arbol inicial ==~n"), tree(),
    B1 = snapshot(),
    io:format("~n== 1) Matamos sensor_a (one_for_one) ==~n"),
    kill(sensor_a), timer:sleep(300), tree(),
    io:format("Reiniciados: ~p~n", [changed(B1, snapshot())]),
    B2 = snapshot(),
    io:format("~n== 2) Matamos el store (rest_for_one) ==~n"),
    kill(let_it_crash_store), timer:sleep(300), tree(),
    io:format("Reiniciados: ~p~n", [changed(B2, snapshot())]),
    io:format("~nEl promedio sigue disponible: ~p~n", [let_it_crash_agg:average()]),
    ok.
