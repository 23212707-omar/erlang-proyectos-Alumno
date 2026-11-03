%% Envoltorio generico: convierte cualquier modulo que implemente el behaviour
%% plugin_sinks_sink en un proceso OTP suscrito a las lecturas.
-module(plugin_sinks_worker).
-behaviour(gen_server).

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(GROUP, plugin_sinks_readings).

start_link(Mod, Opts) ->
    gen_server:start_link(?MODULE, {Mod, Opts}, []).

init({Mod, Opts}) ->
    case Mod:init(Opts) of
        {ok, ModState} ->
            ok = pg:join(?GROUP, self()),
            {ok, #{mod => Mod, state => ModState}};
        {error, Reason} ->
            {stop, Reason}
    end.

handle_call(_Request, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({reading, Reading}, #{mod := Mod, state := ModState} = State) ->
    {ok, NewModState} = Mod:write(Reading, ModState),
    {noreply, State#{state := NewModState}}.

terminate(Reason, #{mod := Mod, state := ModState}) ->
    case erlang:function_exported(Mod, terminate, 2) of
        true -> Mod:terminate(Reason, ModState);
        false -> ok
    end.
