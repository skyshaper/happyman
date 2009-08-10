-module(happyman).
-export([start/0]).

-define(TCP_OPTIONS, [list, {packet, line}, {active, false}, {reuseaddr, true}]).

listen() ->
    {ok, LSocket} = gen_tcp:listen(6666, [{ip, {172,22,68,1}} | ?TCP_OPTIONS]),
    accept(LSocket).

accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(fun() -> handle_client(Socket) end),
    accept(LSocket).

handle_client(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Message} ->
            irc ! {message, Message},
            handle_client(Socket);
        {error, closed} ->
            ok
    end.

handle_irc(Socket) ->
    ssl:setopts(Socket, [{active, once}]),
    receive
        {message, Message} ->
            ssl:send(Socket, "PRIVMSG #skyshaper :"),
            ssl:send(Socket, Message),
            handle_irc(Socket);
        {ssl, Socket, Data} ->
            io:format("~s", [Data]),
            {ok, Fields} = regexp:split(Data, " "),
            Ret = string:to_integer(lists:nth(2, Fields)),
            case Ret of
                {error,no_integer} ->
                    Command = lists:nth(1, Fields),
                    if
                        "PING" == Command ->
                            ssl:send(Socket, "PONG "),
                            ssl:send(Socket, lists:nth(2, Fields)),
                            ssl:send(Socket, "\n");
                        true ->
                            ok
                    end;
                {Code, []} ->
                    irc_event(Socket, Code)
            end,
            handle_irc(Socket);
        {ssl_error, Socket, _} ->
            timer:sleep(5000),
            connect_irc()
    end.

irc_event(Socket, Code) ->
    %% End of MOTD
    case Code of
        376 ->
            ssl:send(Socket, "JOIN #skyshaper\n");
        _Else ->
            ok
    end.

connect_irc() ->
    application:start(ssl),
    {ok, Socket} = ssl:connect('irc.oftc.net', 6697, ?TCP_OPTIONS),
    ssl:send(Socket, "NICK happyman\n"),
    ssl:send(Socket, "USER happyman * * happyman\n"),
    handle_irc(Socket).

start() ->
    Pid = spawn(fun() -> connect_irc() end),
    register(irc, Pid),
    listen().
