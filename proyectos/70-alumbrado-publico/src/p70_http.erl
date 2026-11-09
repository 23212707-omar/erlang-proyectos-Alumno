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
    {"/api/catalogo/resumen", p70_api_h, catalogo_resumen},
    {"/api/catalogo/puntos", p70_api_h, catalogo_puntos},
    {"/api/catalogo/lamparas/:id", p70_api_h, catalogo_lampara},
    {"/api/simulador", p70_api_h, simulador_estado},
    {"/api/simulador/iniciar", p70_api_h, simulador_iniciar},
    {"/api/simulador/detener", p70_api_h, simulador_detener},
    {"/api/simulador/escenarios/poste", p70_api_h, simulador_poste},
    {"/api/simulador/escenarios/circuito", p70_api_h, simulador_circuito},
    {"/", cowboy_static, {priv_file, p70_alumbrado_publico, "www/index.html"}},
    {"/[...]", cowboy_static, {priv_dir, p70_alumbrado_publico, "www"}}
  ]}]),
  cowboy:start_clear(?MODULE, [{port, Port}], #{env => #{dispatch => Dispatch}}).

stop() ->
  cowboy:stop_listener(?MODULE).
