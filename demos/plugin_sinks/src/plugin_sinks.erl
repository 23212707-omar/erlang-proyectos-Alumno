%% API de la demo: agregar, quitar y listar salidas en caliente.
-module(plugin_sinks).

-export([add_sink/2, remove_sink/1, sinks/0, dump/1]).

-define(GROUP, plugin_sinks_readings).

-spec add_sink(module(), map()) -> {ok, pid()} | {error, term()}.
add_sink(Mod, Opts) ->
    case is_sink(Mod) of
        true -> plugin_sinks_sink_sup:start_sink(Mod, Opts);
        false -> {error, {not_a_sink, Mod}}
    end.

-spec remove_sink(pid()) -> ok | {error, not_found}.
remove_sink(Pid) ->
    supervisor:terminate_child(plugin_sinks_sink_sup, Pid).

-spec sinks() -> [{pid(), module()}].
sinks() ->
    lists:append([sink_info(Pid) || Pid <- pg:get_members(?GROUP)]).

%% Una salida puede morir entre pg:get_members/1 y sys:get_state/1 (justo lo que
%% hace plugin_sinks_flaky); se omite en vez de propagar el fallo a quien consulta.
sink_info(Pid) ->
    try sys:get_state(Pid) of
        #{mod := Mod} -> [{Pid, Mod}]
    catch
        exit:_ -> []
    end.

%% Estado interno de la salida (p. ej. las lecturas guardadas por plugin_sinks_memory).
-spec dump(pid()) -> term().
dump(Pid) ->
    maps:get(state, sys:get_state(Pid)).

is_sink(Mod) ->
    {module, Mod} =:= code:ensure_loaded(Mod)
        andalso erlang:function_exported(Mod, init, 1)
        andalso erlang:function_exported(Mod, write, 2).
