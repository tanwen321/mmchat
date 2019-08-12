-module(mmchat_server).

-export([start/0, start_server/0]).
-include("../include/mmchat.hrl").

start_server() ->
    application:ensure_all_started(mmchat).

start() ->
	register(?SERVERNAME, spawn(fun() -> chat() end)).

chat() ->
    process_flag(trap_exit, true),
    start_chat().

start_chat() ->
    _ = erlang:send_after(?CACHETIME, self(), clear_cache),
    receive
    	{init_sock, Pid, Uid} ->
            _ = erlang:monitor(process, Pid),
    		mmchat_data:init_data(Pid, Uid);
    	{send_msg, Pid, Uid, Msg} ->
    		mmchat_data:send_group_msg(Pid, Uid, Msg);
    	{out_sock, Pid} ->
    		mmchat_data:out_sock(Pid);
        {'DOWN', _, process, Pid, _} ->
            mmchat_data:out_sock(Pid);
        clear_cache ->
            clear_cache();
		Error ->
	    	io:format("mm chat receive error msg:~p~n", [Error])
	end,  	
	chat().

clear_cache() ->
    case ets:first(user_data) of
        '$end_of_table' ->
            ok;
        Key ->
            [#user_data{utime={A,B,_}}] = ets:lookup(user_data, Key),
            {A1,B1,_} = os:timestamp(),
            if (A1-A) * 1000000 + (B-B1) > ?CACHETIME ->
                ets:delete(user_data, Key),
                clear_cache(Key);
            true ->
                clear_cache(Key)
            end
    end.

clear_cache(K) ->
    case ets:next(user_data, K) of
        '$end_of_table' ->
            ok;
        Key ->
            [#user_data{utime={A,B,_}}] = ets:lookup(user_data, Key),
            {A1,B1,_} = os:timestamp(),
            if (A1-A) * 1000000 + (B-B1) > ?CACHETIME ->
                ets:delete(user_data, Key),
                clear_cache(Key);
            true ->
                clear_cache(Key)
            end
    end.