%% hot_upgrade:upgrade() compila priv/versions/hot_upgrade_counter.erl y lo carga
%% en el proceso que ya esta corriendo, con la misma secuencia que usan los releases:
%% suspender -> cargar -> change_code -> reanudar.
-module(hot_upgrade).

-export([upgrade/0, version/0]).

-define(MOD, hot_upgrade_counter).

version() ->
    ?MOD:version().

-spec upgrade() -> {ok, #{pid := pid(), from := term(), to := term()}} | {error, term()}.
upgrade() ->
    Pid = whereis(?MOD),
    From = ?MOD:version(),
    Source = filename:join([priv_dir(), "versions", "hot_upgrade_counter.erl"]),
    case compile:file(Source, [binary, return_errors, debug_info]) of
        {ok, ?MOD, Bin} ->
            ok = sys:suspend(?MOD),
            try
                %% purge: descarta codigo "old" de una carga anterior para poder cargar otro.
                _ = code:purge(?MOD),
                {module, ?MOD} = code:load_binary(?MOD, Source, Bin),
                ok = sys:change_code(?MOD, ?MOD, From, []),
                {ok, #{pid => Pid, from => From, to => ?MOD:version()}}
            after
                ok = sys:resume(?MOD)
            end;
        Error ->
            {error, Error}
    end.

%% priv/ junto al ebin del modulo: funciona con rebar3 shell y con `erl -pa`.
priv_dir() ->
    Ebin = filename:dirname(code:which(?MODULE)),
    filename:join(filename:dirname(Ebin), "priv").
