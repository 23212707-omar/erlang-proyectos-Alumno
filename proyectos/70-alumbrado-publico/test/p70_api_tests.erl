-module(p70_api_tests).
-include_lib("eunit/include/eunit.hrl").

%% Cada prueba arranca el arbol, levanta el listener en un puerto libre y al final
%% lo detiene y espera a que el supervisor termine.
api_test_() ->
  {foreach,
   fun() ->
     {ok, _} = application:ensure_all_started(cowboy),
     {ok, _} = application:ensure_all_started(inets),
     {ok, Sup} = p70_alumbrado_publico_sup:start_link(),
     {ok, _} = p70_http:start(0),
     {Sup, ranch:get_port(p70_http)}
   end,
   fun({Sup, _Puerto}) ->
     ok = p70_http:stop(),
     Ref = monitor(process, Sup),
     unlink(Sup),
     exit(Sup, shutdown),
     receive {'DOWN', Ref, process, Sup, _} -> ok end
   end,
   [fun post_crea_falla/1,
    fun quince_posts_una_falla_en_el_mapa/1,
    fun flujo_asignar_y_reparar/1,
    fun falla_inexistente_404/1,
    fun fuente_invalida_400/1,
    fun detalle_con_fuentes/1,
    fun bitacora_registra_eventos/1,
    fun luminaria_desconocida_404/1,
    fun falla_con_ubicacion/1,
    fun resumen_del_catalogo/1,
    fun puntos_y_luminaria_del_catalogo/1,
    fun simulador_por_http/1,
    fun reporte_por_direccion/1,
    fun direccion_invalida_inexistente_o_ambigua/1,
    fun metricas_prometheus/1,
    fun metricas_con_falla_reparada/1,
    fun diagnostico_con_recon/1]}.

post_crea_falla({_Sup, Puerto}) ->
  ?_test(begin
    Respuesta = peticion(post, Puerto, "/api/lamparas/L-0001/falla",
                         "{\"prioridad\":\"alta\"}"),
    ?assertMatch({201, #{<<"resultado">> := <<"nueva">>}}, Respuesta)
  end).

%% Caso del escenario: 15 reportes del mismo poste -> una sola falla en el mapa.
quince_posts_una_falla_en_el_mapa({_Sup, Puerto}) ->
  ?_test(begin
    [{_, _} = peticion(post, Puerto, "/api/lamparas/L-0002/falla", "{}")
     || _ <- lists:seq(1, 15)],
    {200, #{<<"fallas">> := Fallas}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch([#{<<"reportes">> := 15, <<"estado">> := <<"reportada">>}], Fallas)
  end).

flujo_asignar_y_reparar({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0003/falla", "{}"),
    ?assertMatch({200, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"asignar\",\"cuadrilla\":\"cuadrilla_1\"}")),
    %% La cuadrilla aparece con su ruta de una parada.
    {200, #{<<"cuadrillas">> := [Ruta]}} = peticion(get, Puerto, "/api/cuadrillas/rutas", ""),
    ?assertMatch(#{<<"cuadrilla">> := <<"cuadrilla_1">>,
                   <<"paradas">> := [#{<<"luminaria">> := <<"L-0003">>}],
                   <<"distancia_km">> := _}, Ruta),
    ?assertMatch({200, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"reparar\"}")),
    %% Reparada ya no esta en ninguna ruta.
    ?assertMatch({200, #{<<"cuadrillas">> := []}}, peticion(get, Puerto, "/api/cuadrillas/rutas", "")),
    %% Reparar dos veces es una transicion invalida.
    ?assertMatch({409, _}, peticion(patch, Puerto, "/api/fallas/L-0003",
      "{\"accion\":\"reparar\"}"))
  end).

falla_inexistente_404({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({404, _}, peticion(patch, Puerto, "/api/fallas/NO-EXISTE",
                                    "{\"accion\":\"reparar\"}"))).

fuente_invalida_400({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({400, _}, peticion(post, Puerto, "/api/lamparas/L-0004/falla",
                                    "{\"fuente\":\"otra\"}"))).

%% El detalle cuenta cuantos reportes vienen de cada fuente.
detalle_con_fuentes({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"telemetria\"}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"telemetria\"}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0005/falla",
                        "{\"fuente\":\"ciudadano\"}"),
    {200, Detalle} = peticion(get, Puerto, "/api/fallas/L-0005", ""),
    ?assertMatch(#{<<"fuentes">> := #{<<"telemetria">> := 2, <<"ciudadano">> := 1},
                   <<"reportes">> := 3,
                   <<"reincidencias">> := 0}, Detalle),
    ?assert(is_integer(maps:get(<<"reportada_en">>, Detalle)))
  end).

%% La bitacora lista los eventos, el mas reciente primero.
bitacora_registra_eventos({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0006/falla", "{}"),
    {200, _} = peticion(post, Puerto, "/api/lamparas/L-0006/falla", "{}"),
    {200, _} = peticion(patch, Puerto, "/api/fallas/L-0006",
      "{\"accion\":\"asignar\",\"cuadrilla\":\"cuadrilla_2\"}"),
    {200, #{<<"eventos">> := Eventos}} = peticion(get, Puerto, "/api/bitacora", ""),
    Tipos = [maps:get(<<"tipo">>, E) || E <- Eventos],
    ?assertEqual([<<"asignada">>, <<"agrupada">>, <<"nueva">>], Tipos)
  end).

%% Reportar una luminaria que no esta en el catalogo es un error.
luminaria_desconocida_404({_Sup, Puerto}) ->
  ?_test(
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/lamparas/L-9999/falla", "{}"))).

%% El mapa de fallas trae la ubicacion que viene del catalogo.
falla_con_ubicacion({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0010/falla", "{}"),
    {200, #{<<"fallas">> := [Falla]}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch(#{<<"luminaria">> := <<"L-0010">>, <<"sector">> := _,
                   <<"direccion">> := _, <<"circuito">> := _}, Falla),
    ?assert(is_float(maps:get(<<"lat">>, Falla))),
    ?assert(is_float(maps:get(<<"lon">>, Falla)))
  end).

resumen_del_catalogo({_Sup, Puerto}) ->
  ?_test(begin
    {200, Resumen} = peticion(get, Puerto, "/api/catalogo/resumen", ""),
    ?assertMatch(#{<<"total">> := 5000, <<"sectores">> := [_ | _]}, Resumen)
  end).

puntos_y_luminaria_del_catalogo({_Sup, Puerto}) ->
  ?_test(begin
    {200, #{<<"puntos">> := Puntos}} = peticion(get, Puerto, "/api/catalogo/puntos", ""),
    ?assertEqual(5000, length(Puntos)),
    ?assertMatch({200, #{<<"id">> := <<"L-0042">>}},
                 peticion(get, Puerto, "/api/catalogo/lamparas/L-0042", "")),
    ?assertMatch({404, _}, peticion(get, Puerto, "/api/catalogo/lamparas/L-9999", ""))
  end).

%% El simulador por HTTP: estado, escenario del poste y del circuito, iniciar y detener.
simulador_por_http({_Sup, Puerto}) ->
  ?_test(begin
    ?assertMatch({200, #{<<"activo">> := false, <<"reportes_por_dia">> := 80}},
                 peticion(get, Puerto, "/api/simulador", "")),
    ?assertMatch({200, #{<<"enviados">> := 15, <<"nuevas">> := 1, <<"agrupadas">> := 14}},
                 peticion(post, Puerto, "/api/simulador/escenarios/poste", "{}")),
    {200, #{<<"fallas">> := Fallas}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertMatch([#{<<"luminaria">> := <<"L-0777">>, <<"reportes">> := 15}], Fallas),
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/simulador/escenarios/poste",
                                    "{\"luminaria\":\"L-9999\"}")),
    ?assertMatch({200, #{<<"luminarias">> := 40, <<"nuevas">> := 1}},
                 peticion(post, Puerto, "/api/simulador/escenarios/circuito", "{}")),
    {200, #{<<"fallas">> := Fallas2}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertEqual(2, length(Fallas2)),
    [DeCircuito] = [F || #{<<"luminaria">> := <<"C-CEN-01">>} = F <- Fallas2],
    ?assertMatch(#{<<"afectadas">> := 40, <<"circuito">> := <<"C-CEN-01">>, <<"sector">> := _}, DeCircuito),
    ?assert(is_float(maps:get(<<"lat">>, DeCircuito))),
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/simulador/escenarios/circuito",
                                    "{\"circuito\":\"C-XXX-99\"}")),
    ?assertMatch({200, #{<<"activo">> := true}}, peticion(post, Puerto, "/api/simulador/iniciar", "{}")),
    ?assertMatch({200, #{<<"activo">> := false}}, peticion(post, Puerto, "/api/simulador/detener", "{}"))
  end).

%% La misma luminaria reportada con la direccion del catalogo y con otra forma de
%% escribirla (mayusculas, "No." en vez de "#") se agrupa en una sola falla.
reporte_por_direccion({_Sup, Puerto}) ->
  ?_test(begin
    {Id, Direccion} = direccion_unica(),
    Variante = string:uppercase(binary:replace(Direccion, <<"#">>, <<"No. ">>)),
    ?assertMatch({201, #{<<"luminaria">> := Id, <<"resultado">> := <<"nueva">>}},
                 peticion(post, Puerto, "/api/reportes", cuerpo_direccion(Direccion))),
    ?assertMatch({200, #{<<"luminaria">> := Id, <<"resultado">> := <<"agrupada">>}},
                 peticion(post, Puerto, "/api/reportes", cuerpo_direccion(Variante))),
    {200, #{<<"fallas">> := Fallas}} = peticion(get, Puerto, "/api/mapa/fallas", ""),
    ?assertEqual(1, length([F || #{<<"luminaria">> := L} = F <- Fallas, L =:= Id]))
  end).

direccion_invalida_inexistente_o_ambigua({_Sup, Puerto}) ->
  ?_test(begin
    ?assertMatch({400, _}, peticion(post, Puerto, "/api/reportes", "{}")),
    ?assertMatch({400, _}, peticion(post, Puerto, "/api/reportes", "{\"direccion\":\"sin numero\"}")),
    ?assertMatch({404, _}, peticion(post, Puerto, "/api/reportes", "{\"direccion\":\"Av. Inexistente 99999\"}")),
    {Id, Direccion} = direccion_repetida(),
    {409, #{<<"candidatas">> := Candidatas}} =
      peticion(post, Puerto, "/api/reportes", cuerpo_direccion(Direccion)),
    ?assert(lists:member(Id, Candidatas)),
    ?assert(length(Candidatas) >= 2)
  end).

cuerpo_direccion(Direccion) ->
  binary_to_list(iolist_to_binary(json:encode(#{direccion => Direccion}))).

%% Una luminaria de las primeras 80 cuya direccion solo corresponde a ella.
direccion_unica() ->
  hd([{Id, D} || N <- lists:seq(1, 80),
                 Id <- [iolist_to_binary(io_lib:format("L-~4..0w", [N]))],
                 {ok, #{direccion := D}} <- [p70_catalogo:buscar(Id)],
                 p70_direccion:resolver(D) =:= {ok, Id}]).

%% Una luminaria cuya direccion comparte otra del catalogo (dos postes en el mismo numero).
direccion_repetida() ->
  hd([{Id, D} || [Id, _, _] <- p70_catalogo:puntos(),
                 {ok, #{direccion := D}} <- [p70_catalogo:buscar(Id)],
                 {error, {ambigua, _}} <- [p70_direccion:resolver(D)]]).

%% GET /metrics: formato de texto de Prometheus con las fallas vigentes.
metricas_prometheus({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0001/falla", "{\"prioridad\":\"alta\"}"),
    {200, Texto} = peticion_texto(Puerto, "/metrics"),
    [?assertNotEqual(nomatch, binary:match(Texto, Esperado)) || Esperado <- [
       <<"# TYPE p70_lamparas_apagadas gauge\n">>,
       <<"p70_lamparas_apagadas 1\n">>,
       <<"p70_fallas{estado=\"reportada\"} 1\n">>,
       <<"p70_fallas{estado=\"asignada\"} 0\n">>,
       <<"p70_fallas_abiertas_por_prioridad{prioridad=\"alta\"} 1\n">>,
       <<"# TYPE p70_fallas_abiertas_por_sector gauge\n">>,
       <<"# TYPE p70_beam_procesos gauge\n">>]]
  end).

%% Una falla reparada ya no cuenta como lampara apagada y entra al resumen de reparacion.
metricas_con_falla_reparada({_Sup, Puerto}) ->
  ?_test(begin
    {201, _} = peticion(post, Puerto, "/api/lamparas/L-0004/falla", "{}"),
    {200, _} = peticion(patch, Puerto, "/api/fallas/L-0004",
                        "{\"accion\":\"asignar\",\"cuadrilla\":\"cuadrilla_1\"}"),
    {200, _} = peticion(patch, Puerto, "/api/fallas/L-0004", "{\"accion\":\"reparar\"}"),
    {200, Texto} = peticion_texto(Puerto, "/metrics"),
    [?assertNotEqual(nomatch, binary:match(Texto, Esperado)) || Esperado <- [
       <<"p70_lamparas_apagadas 0\n">>,
       <<"p70_fallas{estado=\"reparada\"} 1\n">>,
       <<"p70_reparacion_segundos_count 1\n">>]]
  end).

%% GET /api/diagnostico: lo que recon ve en la VM.
diagnostico_con_recon({_Sup, Puerto}) ->
  ?_test(begin
    {200, Datos} = peticion(get, Puerto, "/api/diagnostico", ""),
    ?assertMatch(#{<<"procesos">> := _, <<"memoria_total_bytes">> := _,
                   <<"mas_memoria">> := [#{<<"proceso">> := _, <<"valor">> := _} | _],
                   <<"mas_cola_mensajes">> := _}, Datos)
  end).

%% Como peticion/4 pero devuelve el cuerpo tal cual (texto, no JSON).
peticion_texto(Puerto, Ruta) ->
  Url = "http://127.0.0.1:" ++ integer_to_list(Puerto) ++ Ruta,
  {ok, {{_, Codigo, _}, _Cabeceras, Resp}} = httpc:request(get, {Url, []}, [], []),
  {Codigo, list_to_binary(Resp)}.

peticion(Metodo, Puerto, Ruta, Cuerpo) ->
  Url = "http://127.0.0.1:" ++ integer_to_list(Puerto) ++ Ruta,
  Pedido = case Metodo of
    get -> {Url, []};
    _ -> {Url, [], "application/json", Cuerpo}
  end,
  {ok, {{_, Codigo, _}, _Cabeceras, Resp}} = httpc:request(Metodo, Pedido, [], []),
  {Codigo, json:decode(list_to_binary(Resp))}.
