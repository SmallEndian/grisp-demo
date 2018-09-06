% @doc robot public API.
% @end
-module(robot).

-behavior(application).

% Callbacks
-export([start/2]).
-export([stop/1]).
-export([launch_blue/0]).
-export([list_files/1]).
-export([ls/1, all_mods/0, connect/0, con/0, lww/0]).

%--- Callbacks -----------------------------------------------------------------

start(_Type, _Args) ->
    {ok, Supervisor} = robot_sup:start_link(),
    [grisp_led:flash(1, aqua, 700),
    grisp_led:flash(2, green, 700)],
    %timer:sleep(2000),
    % We don't use these anymore.
    %io:format("GPB version: ~p ~n", [antidote:gpb_version_as_string()]),
    io:format("~n"),
    
    list_files("."),
    list_files("robot"),
    list_files("robot/lib"),
    list_files("robot/bin"),
    list_files("robot/releases"),

    %application:ensure_all_started(antidote_pb),
    %
    
    %io:format(anditote_pb_socket:start("127.0.0.1", "8080")),
    %antidote_pb:module_info(),
    %grisp_led:pattern(2, [{100, Red}]),
    grisp_led:off(1),
    grisp_led:off(2),
    {ok, Supervisor}.

stop(_State) -> ok.

ls(E) -> list_files(E).
list_files(Path) ->
	{ok, Str} = file:list_dir(Path),
	io:format("~p : ", [Path]),
	[ io:format("~p  ", [X]) || X <- Str],
	io:format("~n")
	.

all_mods()-> [io:format("~p ~n", [E]) || {E, _} <-  code:all_loaded() ].

con()-> {ok, Pid} = antidotec_pb_socket:start("192.168.43.81", 8087),

	BObj = {"A", riak_dt_pncounter, "A"},

	{ok, TxId} = antidotec_pb:start_transaction(Pid, term_to_binary(ignore), []),

	Obj = antidotec_counter:increment(1, antidotec_counter:new()),
	{ok, TimeStamp} = antidotec_pb:commit_transaction(Pid, TxId),
	antidotec_counter:to_ops(BObj, Obj)

	.

lww() -> ok.

connect()->
	{ok, Pid} = antidotec_pb_socket:start("localhost", 8087),
	BObj = {"A",  antidote_crdt_counter, "B"},
	{ok, TxId} = antidotec_pb:start_transaction(Pid, term_to_binary(ignore), []),
	Obj = antidotec_counter:increment(1, antidotec_counter:new()),
	ok = antidotec_pb:update_objects(Pid, antidotec_counter:to_ops(BObj, Obj), TxId),
	{ok, TimeStamp} = antidotec_pb:commit_transaction(Pid, TxId),
	_Disconnected = antidotec_pb_socket:stop(Pid),
ok.

launch_blue() ->
	grisp_led:flash(2, blue, 1000),
	ok.
