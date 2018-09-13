% @doc robot public API.
% @end
-module(robot).

-behavior(application).

% Callbacks
-export([start/2]).
-export([stop/1]).
-export([list_files/1]).
-export([ls/1, all_mods/0,  flash_ok/0, l/0, test/0, gt/0, print/1]).
-export([inc/0, dec/0]).
%--- Callbacks -----------------------------------------------------------------

%% Constant values
bobj() ->  {"A",  antidote_crdt_counter, "B"}.
ip() -> {192,168,43,77}.
port() -> 
			case not grisp_gpio:get(jumper_1) of
				true -> 8088;
				false -> 8087
			end.



start(_Type, _Args) ->
	{ok, Supervisor} = robot_sup:start_link(),
	_ = [grisp_led:flash(1, aqua, 700),
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
				true -> io:format("This is Minus~n");
				false -> io:format("This is Plus~n")
			end,
	grisp:add_device(spi1, pmod_nav),

	spawn(fun test/0),
	register(printer, spawn(fun printer/0)),



	flash_ok(),
	%grisp_led:off(1),
	{ok, Supervisor}.

stop(_State) -> ok.


%%%%% Debug Functions
ls(E) -> list_files(E).
list_files(Path) ->
	{ok, Str} = file:list_dir(Path),
	io:format("~p : ", [Path]),
	[ io:format("~p  ", [X]) || X <- Str],
	io:format("~n")
	.

all_mods() -> lists:map( fun (X) -> io:format("~p ~n", [X]) end, 
			 lists:sort([X || {X, _} <- code:all_loaded()])).




%% Simple transactions on a counter
dec()->
	{ok, Pid} = antidotec_pb_socket:start(ip(), port()),
	BObj = bobj(),	
	{ok, TxId} = antidotec_pb:start_transaction(Pid, term_to_binary(ignore), []),
	Obj = antidotec_counter:decrement(1, antidotec_counter:new()),
	ok = antidotec_pb:update_objects(Pid, antidotec_counter:to_ops(BObj, Obj), TxId),
	{ok, _TimeStamp} = antidotec_pb:commit_transaction(Pid, TxId),
	_Disconnected = antidotec_pb_socket:stop(Pid),
	ok.


inc()->
	{ok, Pid} = antidotec_pb_socket:start(ip(), port()),
	BObj = bobj(),	
	{ok, TxId} = antidotec_pb:start_transaction(Pid, term_to_binary(ignore), []),
	Obj = antidotec_counter:increment(1, antidotec_counter:new()),
	ok = antidotec_pb:update_objects(Pid, antidotec_counter:to_ops(BObj, Obj), TxId),
	{ok, _TimeStamp} = antidotec_pb:commit_transaction(Pid, TxId),
	_Disconnected = antidotec_pb_socket:stop(Pid),
	io:format("X++ "),
	ok.

gt() ->
	{ok, Pid} = antidotec_pb_socket:start(ip(), port()),
	BObj = bobj(),	
	{ok, TxId} = antidotec_pb:start_transaction(Pid, term_to_binary(ignore), []),
	{ok, Val} = antidotec_pb:read_objects(Pid, [BObj], TxId),
	 {ok, _} = antidotec_pb:commit_transaction(Pid, TxId),
	_Disconnected = antidotec_pb_socket:stop(Pid),
	antidotec_counter:value(hd(Val))
	.







printer() ->
	receive 
		N when is_integer(N) -> print(N),
					flash(),
					timer:sleep(200);
		_ -> ok
	end,
	printer()
	.





%% Initiate the infinite event loop
test() ->
	acl({0,0,0}, -1).
acl(_State, 0) -> ok;
acl(State, N) ->
	Tuple = case pmod_nav:read(acc, [out_x_xl,out_y_xl,out_z_xl]) of 
			[A,B,C] -> {A,B,C}
		end,
	Adds = fun({A,B,C}) -> abs(A+B+C) end,
	%io:format("~p ~n", [Tuple]),
	timer:sleep(250),
	case (Diff = (Adds(Tuple) - Adds(State))) > 0.5 of
	     true -> 
			case not grisp_gpio:get(jumper_1) of
				true -> inc();
				false ->dec()
			end,
		     New_Val = gt(),
			%io:format("Changed! ~p : ~p ~n", [Diff, New_Val]),
		     io:format("~p ~n", [New_Val]),
			printer ! New_Val;
		false -> ok
	end,
	acl(Tuple, N-1)
	.


%% Led output
print(Number) ->
	Tens = trunc(Number/10),
	Units = trunc(Number) rem 10,
	Colors = fun L(0) -> [{infinity, off}];
L(N) -> [{500, rainbow()}, {300, off}]++L(N-1)
				end,
				grisp_led:pattern(1, Colors(Tens)),
				timer:sleep(Tens * 800),
				grisp_led:pattern(2, Colors(Units)),
				timer:sleep(Units * 800)
				.
l() -> flash_ok().
flash_ok() -> 
	grisp_led:pattern(1, [{700, red}, {100, off}, {700, green},  {100, off}, {700, blue}, {infinity, off}]),
	grisp_led:pattern(2, [{700, blue}, {100, off}, {700, green},  {100, off}, {700, red}, {infinity, off}]).
flash() -> 
	grisp_led:pattern(1, [{200, white}, {infinity, off}]),
	grisp_led:pattern(2, [{200, white}, {infinity, off}]).

rainbow() ->
	Colors = [ black , blue , green , aqua , red , magenta , yellow , white ],
	Length = length(Colors),
	lists:nth(rand:uniform(Length), Colors)
	.

