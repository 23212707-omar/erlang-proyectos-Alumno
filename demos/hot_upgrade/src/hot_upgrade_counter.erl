%% Version 1: el estado es un entero. La version 2 vive en priv/versions/ y
%% se carga en caliente con hot_upgrade:upgrade/0.
-module(hot_upgrade_counter).
-behaviour(gen_server).
-vsn(1).

-export([start_link/0, get/0, bump/0, version/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get() -> gen_server:call(?MODULE, get).
bump() -> gen_server:call(?MODULE, bump).
version() -> 1.

init([]) ->
    schedule(),
    {ok, 0}.

handle_call(get, _From, Count) ->
    {reply, Count, Count};
handle_call(bump, _From, Count) ->
    {reply, Count + 1, Count + 1}.

handle_cast(_Msg, Count) ->
    {noreply, Count}.

handle_info(tick, Count) ->
    io:format("[v1] cuenta=~p~n", [Count + 1]),
    schedule(),
    {noreply, Count + 1}.

%% Necesario para que sys:change_code/4 no falle si se re-carga esta misma version.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

schedule() ->
    erlang:send_after(application:get_env(hot_upgrade, tick_ms, 1000), self(), tick).
