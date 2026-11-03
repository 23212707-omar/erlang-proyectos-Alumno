-module(let_it_crash_agg).
-behaviour(gen_server).

-export([start_link/0, average/0]).
-export([init/1, handle_call/3, handle_cast/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Calcula el promedio en el proceso que llama; el server solo existe para
%% mostrar un hijo mas del arbol que depende del store.
average() ->
    gen_server:call(?MODULE, average).

init([]) ->
    {ok, #{}}.

handle_call(average, _From, State) ->
    Values = [V || {_Sensor, V} <- let_it_crash_store:all()],
    Avg = case Values of
              [] -> undefined;
              _ -> lists:sum(Values) / length(Values)
          end,
    {reply, Avg, State};
handle_call(_Other, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.
