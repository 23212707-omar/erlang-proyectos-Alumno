%% Listener HTTP de cowboy: API JSON bajo /api y archivos estaticos (UI de Stitch)
%% desde priv/www. Cowboy supervisa sus propias conexiones (un proceso por request).
-module(p70_http).

-export([start/1, stop/0]).

%% Port = 0 pide un puerto libre al SO (util en pruebas); ranch:get_port/1 lo revela.
start(Port) ->
  Dispatch = cowboy_router:compile([{'_', [
    {"/api/lamparas/:id/falla", p70_api_h, falla},
    {"/api/mapa/fallas", p70_api_h, mapa},
    {"/api/fallas/:id", p70_api_h, falla_id},
    {"/api/bitacora", p70_api_h, bitacora},
    {"/", cowboy_static, {priv_file, p70_alumbrado_publico, "www/index.html"}},
    {"/[...]", cowboy_static, {priv_dir, p70_alumbrado_publico, "www"}}
  ]}]),
  cowboy:start_clear(?MODULE, [{port, Port}], #{env => #{dispatch => Dispatch}}).

stop() ->
  cowboy:stop_listener(?MODULE).
