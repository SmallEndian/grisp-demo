% @doc robot public API.
% @end
-module(robot).

-behavior(application).

% Callbacks
-export([start/2]).
-export([stop/1]).
-export([launch_blue/0]).

%--- Callbacks -----------------------------------------------------------------

start(_Type, _Args) ->
    {ok, Supervisor} = robot_sup:start_link(),
    [grisp_led:flash(1, aqua, 700),
    grisp_led:flash(2, green, 700)],
    timer:sleep(2000),
    io:format("Random definition:~n"),
    io:format(antidote:gpb_version_as_string()),
    Random = fun() ->
        {rand:uniform(2) - 1, rand:uniform(2) -1, rand:uniform(2) - 1}
    end,
    Red = fun() ->
        {1,0,0}
    end,
    grisp_led:pattern(1, [{100, Random}]),
    %grisp_led:pattern(2, [{100, Red}]),
    grisp_led:off(2),
    {ok, Supervisor}.

stop(_State) -> ok.

launch_blue() ->
	grisp_led:flash(2, blue, 1000),
	ok.
