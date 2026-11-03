-module(plugin_sinks_sensor).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(GROUP, plugin_sinks_readings).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    schedule(),
    {ok, #{value => 20.0}}.

handle_call(_Request, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% El sensor no sabe cuantas salidas hay ni de que tipo: solo publica al grupo.
handle_info(sample, #{value := Value} = State) ->
    New = Value + (rand:uniform() - 0.5),
    Reading = #{sensor => temp_1, ts => erlang:system_time(millisecond),
                value => round(New * 10) / 10},
    [Pid ! {reading, Reading} || Pid <- pg:get_members(?GROUP)],
    schedule(),
    {noreply, State#{value := New}}.

schedule() ->
    erlang:send_after(application:get_env(plugin_sinks, interval_ms, 1000), self(), sample).
