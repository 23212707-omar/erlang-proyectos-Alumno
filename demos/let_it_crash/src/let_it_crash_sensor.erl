-module(let_it_crash_sensor).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(INTERVAL, 500).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, Name, []).

init(Name) ->
    erlang:send_after(?INTERVAL, self(), sample),
    {ok, Name}.

handle_call(_Request, _From, Name) ->
    {reply, {error, unsupported}, Name}.

handle_cast(_Msg, Name) ->
    {noreply, Name}.

%% Sin try/catch a proposito: si algo sale mal, el proceso muere y el supervisor decide.
handle_info(sample, Name) ->
    ok = let_it_crash_store:put(Name, rand:uniform(100)),
    erlang:send_after(?INTERVAL, self(), sample),
    {noreply, Name}.
