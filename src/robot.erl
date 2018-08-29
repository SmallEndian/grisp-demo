% @doc robot public API.
% @end
-module(robot).

-behavior(application).

% Callbacks
-export([start/2]).
-export([stop/1]).

%--- Callbacks -----------------------------------------------------------------

start(_Type, _Args) ->
    {ok, Supervisor} = robot_sup:start_link(),
    LEDs = [1, 2],
    [grisp_led:flash(L, blue, 500) || L <- LEDs],
    timer:sleep(7000),
    Random = fun() ->
        {rand:uniform(2) - 1, rand:uniform(2) -1, rand:uniform(2) - 1}
    end,
    Red = fun() ->
        {1,0,0}
    end,
    grisp_led:pattern(1, [{100, Random}]),
    grisp_led:pattern(2, [{100, Red}]),
    {ok, Supervisor}.

stop(_State) -> ok.
