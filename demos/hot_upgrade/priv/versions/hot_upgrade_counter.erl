%% Version 2: el estado pasa de entero a mapa (cuenta + paso) y cada tick suma `step`.
%% code_change/3 migra el estado de la v1 sin reiniciar el proceso.
-module(hot_upgrade_counter).
-behaviour(gen_server).
-vsn(2).

-export([start_link/0, get/0, bump/0, version/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get() -> gen_server:call(?MODULE, get).
bump() -> gen_server:call(?MODULE, bump).
version() -> 2.

init([]) ->
    schedule(),
    {ok, #{count => 0, step => 5}}.

handle_call(get, _From, #{count := Count} = State) ->
    {reply, Count, State};
handle_call(bump, _From, #{count := Count, step := Step} = State) ->
    {reply, Count + Step, State#{count := Count + Step}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(tick, #{count := Count, step := Step} = State) ->
    io:format("[v2] cuenta=~p (paso ~p)~n", [Count + Step, Step]),
    schedule(),
    {noreply, State#{count := Count + Step}}.

code_change(1, Count, _Extra) when is_integer(Count) ->
    {ok, #{count => Count, step => 5}};
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

schedule() ->
    erlang:send_after(application:get_env(hot_upgrade, tick_ms, 1000), self(), tick).
