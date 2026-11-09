%% Supervisor dinamico de fallas: se crea un hijo por cada falla nueva.
-module(p70_falla_sup).
-behaviour(supervisor).

-export([start_link/0, abrir/3]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% Abre una falla nueva y devuelve {ok, Pid}.
abrir(Luminaria, Prioridad, Fuente) ->
  supervisor:start_child(?MODULE, [Luminaria, Prioridad, Fuente]).

%% restart => temporary: si una falla muere, no se reinicia sola porque
%% reiniciaria con el estado vacio y perderia sus reportes. La recuperacion del
%% estado (desde ETS o PostgreSQL) se disena en un paso posterior.
init([]) ->
  Hijo = #{id => p70_falla,
           start => {p70_falla, start_link, []},
           restart => temporary,
           shutdown => 5000,
           type => worker},
  {ok, {#{strategy => simple_one_for_one, intensity => 10, period => 60}, [Hijo]}}.
