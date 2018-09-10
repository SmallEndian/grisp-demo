% @doc robot public API.
% @end
-module(robot).

-behavior(application).

% Callbacks
-export([start/2]).
-export([stop/1]).
-export([launch_blue/0]).
-export([list_files/1]).
-export([ls/1, all_mods/0, connect/0, con/0, lww/0, flash_ok/0, l/0, test/0]).

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

	application:ensure_all_started(antidote_pb_socket),
	%

	%io:format(anditote_pb_socket:start("127.0.0.1", "8080")),
	%antidote_pb:module_info(),
	%grisp_led:pattern(2, [{100, Red}]),

	% When Antidote had been started

	case not grisp_gpio:get(jumper_1) of
		true -> con();
		_ -> ok
	end,

	grisp:add_device(spi1, pmod_nav),

	spawn(fun test/0),



	flash_ok(),
	%grisp_led:off(1),
	{ok, Supervisor}.

stop(_State) -> ok.

l() -> flash_ok().
ls(E) -> list_files(E).
list_files(Path) ->
	{ok, Str} = file:list_dir(Path),
	io:format("~p : ", [Path]),
	[ io:format("~p  ", [X]) || X <- Str],
	io:format("~n")
	.

%all_mods()-> [io:format("~p ~n", [E]) || {E, _} <-  code:all_loaded() ].
all_mods() -> lists:map( fun (X) -> io:format("~p ~n", [X]) end, 
			 lists:sort([X || {X, _} <- code:all_loaded()])).
connect() -> ok.

flash_ok() -> 
	grisp_led:pattern(1, [{700, red}, {100, off}, {700, green},  {100, off}, {700, blue}, {infinity, off}]),
	grisp_led:pattern(2, [{700, blue}, {100, off}, {700, green},  {100, off}, {700, red}, {infinity, off}]).

lww() -> ok.

con()->
	{ok, Pid} = antidotec_pb_socket:start({192,168,43,81}, 8087),
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

test() ->
	acl({0,0,0}, -1).

acl(State, 0) -> ok;
acl(State, N) ->
	Tuple = case pmod_nav:read(acc, [out_x_xl,out_y_xl,out_z_xl]) of 
			[A,B,C] -> {A,B,C}
		end,
	Adds = fun({A,B,C}) -> abs(A+B+C) end,
	%io:format("~p ~n", [Tuple]),
	timer:sleep(250),
	case Diff = (Adds(Tuple) - Adds(State)) > 0.5 of
	     true -> io:format("Changed! ~p~n", [Diff]) ;
	     false -> ok
	end,
	acl(Tuple, N-1)
	.



