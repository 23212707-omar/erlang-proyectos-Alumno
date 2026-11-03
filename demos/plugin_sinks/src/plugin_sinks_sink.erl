%% Contrato que debe cumplir cualquier salida. Agregar un destino nuevo
%% (PostgreSQL, MQTT...) es escribir un modulo con estos callbacks; el sensor no cambia.
-module(plugin_sinks_sink).

-type reading() :: #{sensor := atom(), ts := integer(), value := number()}.
-export_type([reading/0]).

-callback init(Opts :: map()) -> {ok, State :: term()} | {error, term()}.
-callback write(reading(), State :: term()) -> {ok, NewState :: term()}.
-callback terminate(Reason :: term(), State :: term()) -> ok.

-optional_callbacks([terminate/2]).
