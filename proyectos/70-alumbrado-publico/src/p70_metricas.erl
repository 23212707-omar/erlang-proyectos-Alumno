%% Metricas en formato de texto de Prometheus (GET /metrics) y diagnostico de la VM
%% con recon (GET /api/diagnostico). Se calculan al momento de la consulta con lo que
%% hay en el registro de fallas: no hay contadores acumulados, asi que lo ya reparado
%% solo cuenta mientras su falla siga siendo la vigente de esa luminaria.
%% Los textos de ayuda van sin acentos: son listas de caracteres, no binarios.
-module(p70_metricas).

-export([texto/0, diagnostico/0]).

%% Todo el texto de /metrics (binario).
texto() ->
  Fallas = fallas(),
  Abiertas = [F || #{estado := E} = F <- Fallas, E =/= reparada],
  iolist_to_binary([
    bloque("p70_lamparas_apagadas",
           "Luminarias apagadas con falla abierta (una falla de circuito cuenta todas las del circuito)",
           "gauge",
           [serie("p70_lamparas_apagadas", [], lists:sum([maps:get(afectadas, F) || F <- Abiertas]))]),
    bloque("p70_fallas", "Fallas vigentes por estado", "gauge",
           [serie("p70_fallas", [{"estado", atom_to_binary(E, utf8)}],
                  length([F || #{estado := E2} = F <- Fallas, E2 =:= E]))
            || E <- [reportada, asignada, reparada]]),
    bloque("p70_fallas_abiertas_por_sector", "Fallas abiertas por sector", "gauge",
           [serie("p70_fallas_abiertas_por_sector", [{"sector", S}],
                  length([F || #{sector := S2} = F <- Abiertas, S2 =:= S]))
            || S <- sectores(Abiertas)]),
    bloque("p70_fallas_abiertas_por_prioridad", "Fallas abiertas por prioridad efectiva", "gauge",
           [serie("p70_fallas_abiertas_por_prioridad", [{"prioridad", atom_to_binary(P, utf8)}],
                  length([F || #{prioridad := P2} = F <- Abiertas, P2 =:= P]))
            || P <- [alta, media, baja]]),
    bloque("p70_falla_abierta_mas_antigua_segundos", "Antiguedad de la falla abierta mas vieja", "gauge",
           [serie("p70_falla_abierta_mas_antigua_segundos", [], mas_antigua(Abiertas))]),
    reparacion(Fallas),
    bloque("p70_beam_procesos", "Procesos de la VM", "gauge",
           [serie("p70_beam_procesos", [], erlang:system_info(process_count))]),
    bloque("p70_beam_memoria_bytes", "Memoria de la VM por tipo", "gauge",
           [serie("p70_beam_memoria_bytes", [{"tipo", atom_to_binary(T, utf8)}], erlang:memory(T))
            || T <- [total, processes, ets, binary]]),
    bloque("p70_beam_cola_mensajes_maxima", "Cola de mensajes mas larga entre los procesos (recon)", "gauge",
           [serie("p70_beam_cola_mensajes_maxima", [], cola_maxima())])
  ]).

%% JSON de /api/diagnostico: lo que recon ve en la VM ahora mismo.
diagnostico() ->
  #{procesos => erlang:system_info(process_count),
    schedulers => erlang:system_info(schedulers_online),
    memoria_total_bytes => erlang:memory(total),
    mas_memoria => top(memory),
    mas_cola_mensajes => top(message_queue_len)}.

%% --- Datos de las fallas ---

%% Una entrada por falla vigente: estado, prioridad efectiva, sector y luminarias afectadas.
fallas() ->
  [F || {Luminaria, Pid} <- maps:to_list(p70_registro:activas()),
        {ok, F} <- [falla(Luminaria, Pid)]].

falla(Luminaria, Pid) ->
  try p70_falla:estado(Pid) of
    {Estado, Datos} ->
      {Sector, Afectadas} = donde(Luminaria),
      {ok, #{estado => Estado,
             prioridad => p70_falla:prioridad_efectiva(Datos),
             sector => Sector,
             afectadas => Afectadas,
             reportada_en => maps:get(reportada_en, Datos),
             reparada_en => maps:get(reparada_en, Datos, undefined)}}
  catch
    exit:_ -> error
  end.

%% {sector, luminarias afectadas}. Una falla de circuito (id "C-...") afecta a todo el circuito.
donde(<<"C-", _/binary>> = Circuito) ->
  case p70_catalogo:circuito(Circuito) of
    {ok, #{sector := Sector, afectadas := N}} -> {Sector, N};
    error -> {<<"desconocido">>, 1}
  end;
donde(Luminaria) ->
  case p70_catalogo:buscar(Luminaria) of
    {ok, #{sector := Sector}} -> {Sector, 1};
    _ -> {<<"desconocido">>, 1}
  end.

%% Todos los sectores del catalogo (para que salgan en cero) mas los que traigan las fallas.
sectores(Abiertas) ->
  Catalogo = try p70_catalogo:resumen() of
               #{sectores := Lista} -> [S || #{sector := S} <- Lista];
               _ -> []
             catch _:_ -> []
             end,
  lists:usort(Catalogo ++ [S || #{sector := S} <- Abiertas]).

mas_antigua([]) ->
  0;
mas_antigua(Abiertas) ->
  Ahora = erlang:system_time(second),
  lists:max([max(0, Ahora - maps:get(reportada_en, F)) || F <- Abiertas]).

%% Resumen (suma y cuenta) del tiempo de reparacion de las fallas ya reparadas.
reparacion(Fallas) ->
  Tiempos = [R - D || #{reportada_en := D, reparada_en := R} <- Fallas, is_integer(R)],
  bloque("p70_reparacion_segundos", "Tiempo de reparacion de las fallas reparadas vigentes", "summary",
         [serie("p70_reparacion_segundos_sum", [], lists:sum(Tiempos)),
          serie("p70_reparacion_segundos_count", [], length(Tiempos))]).

%% --- recon ---

cola_maxima() ->
  case recon:proc_count(message_queue_len, 1) of
    [{_Pid, N, _Info} | _] -> N;
    _ -> 0
  end.

top(Atributo) ->
  [#{proceso => nombre(Info), valor => Valor} || {_Pid, Valor, Info} <- recon:proc_count(Atributo, 5)].

%% recon da como primer elemento el nombre registrado o, si no tiene, {current_function, MFA}.
nombre([{current_function, {M, F, A}} | _]) -> iolist_to_binary(io_lib:format("~w:~w/~w", [M, F, A]));
nombre([Nombre | _]) when is_atom(Nombre) -> atom_to_binary(Nombre, utf8);
nombre([Nombre | _]) -> iolist_to_binary(io_lib:format("~w", [Nombre]));
nombre(_) -> <<"desconocido">>.

%% --- Formato Prometheus ---

bloque(Nombre, Ayuda, Tipo, Series) ->
  ["# HELP ", Nombre, " ", Ayuda, "\n# TYPE ", Nombre, " ", Tipo, "\n", Series].

serie(Nombre, [], Valor) ->
  [Nombre, " ", integer_to_list(Valor), "\n"];
serie(Nombre, Etiquetas, Valor) ->
  Pares = lists:join(",", [[K, "=\"", escapar(V), "\""] || {K, V} <- Etiquetas]),
  [Nombre, "{", Pares, "} ", integer_to_list(Valor), "\n"].

%% Dentro de una etiqueta hay que escapar \, " y el salto de linea.
escapar(Valor) ->
  B0 = iolist_to_binary(Valor),
  B1 = binary:replace(B0, <<"\\">>, <<"\\\\">>, [global]),
  B2 = binary:replace(B1, <<"\"">>, <<"\\\"">>, [global]),
  binary:replace(B2, <<"\n">>, <<"\\n">>, [global]).
