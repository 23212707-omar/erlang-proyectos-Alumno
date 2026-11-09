-module(p70_alumbrado_publico_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% rest_for_one: p70_registro depende de p70_falla_sup (guarda los pids de sus hijos).
%% Si p70_falla_sup se reinicia, el registro se reinicia tambien y no queda con pids
%% muertos. El orden de la lista es el orden de arranque. p70_bitacora va al final: si
%% falla, solo se reinicia ella y no se pierden las fallas en curso.
init([]) ->
  Children = [
    #{id => p70_alumbrado_publico_server,
      start => {p70_alumbrado_publico_server, start_link, []},
      restart => permanent,
      shutdown => 5000,
      type => worker},
    #{id => p70_falla_sup,
      start => {p70_falla_sup, start_link, []},
      restart => permanent,
      shutdown => infinity,
      type => supervisor},
    #{id => p70_registro,
      start => {p70_registro, start_link, []},
      restart => permanent,
      shutdown => 5000,
      type => worker},
    #{id => p70_bitacora,
      start => {p70_bitacora, start_link, []},
      restart => permanent,
      shutdown => 5000,
      type => worker}
  ],
  {ok, {#{strategy => rest_for_one, intensity => 10, period => 60}, Children}}.
