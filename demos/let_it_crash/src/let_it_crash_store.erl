-module(let_it_crash_store).
-behaviour(gen_server).

-export([start_link/0, put/2, all/0]).
-export([init/1, handle_call/3, handle_cast/2]).

-define(TABLE, let_it_crash_readings).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

put(Sensor, Value) ->
    true = ets:insert(?TABLE, {Sensor, Value}),
    ok.

all() ->
    ets:tab2list(?TABLE).

%% La tabla muere con su dueño: por eso el store es el primer hijo del supervisor.
init([]) ->
    ?TABLE = ets:new(?TABLE, [named_table, public, set]),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.
