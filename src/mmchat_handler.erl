-module(mmchat_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

-include("../include/mmchat.hrl").

-record(sock_state, {uid, cookie}).

%-define(LOG(X), io:format("{~p,~p}: ~p~n", [?MODULE,?LINE,X])).
-define(LOG(X), ok).

init({tcp, http}, _Req, _Opts) ->
	{upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
	case get_cookie(Req) of
		{ok, Uid, Cook, Req2} ->
			case whereis(?SERVERNAME) of
				undefined ->
					{ok, Req2, #sock_state{}};
				_ ->
					?SERVERNAME ! {init_sock, self(), Uid},
					{ok, Req2, #sock_state{uid=Uid, cookie = Cook}}
			end;
		{no, Req2} ->
			{ok, Req2, #sock_state{}}
	end.

websocket_handle(_Msg, Req, #sock_state{uid=undefined} = State) ->
	?LOG(_Msg),
	{reply, {text, <<"wrong">>}, Req, State};
websocket_handle({text, <<"ping">>}, Req, State) ->
	?LOG("ping"),
	{reply, {text, <<"pong">>}, Req, State};
websocket_handle({text, Msg}, Req, #sock_state{uid=Uid} = State) ->
	?LOG(Msg),
	?SERVERNAME ! {send_msg, self(), Uid, Msg},
	{ok, Req, State};
websocket_handle(_Data, Req, State) ->
	?LOG(_Data),
	% {reply, {text, Data}, Req, State}.
	{ok, Req, State}.

% websocket_info({timeout, _Ref, Msg}, Req, State) ->
% %	erlang:start_timer(1000, self(), <<"How' you doin'?">>),
% 	{reply, {text, Msg}, Req, State};
websocket_info({init, Msg}, Req, State) ->
	?LOG(Msg),
	{reply, {text, Msg}, Req, State};
websocket_info(Info, Req, State) ->
	?LOG(Info),
%	{ok, Req, State}.
	{reply, {text, Info}, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
	?LOG(_Reason),
	?SERVERNAME ! {out_sock, self()},
	ok.


get_cookie(Req) ->
	case cowboy_req:cookie(<<"mmssid">>, Req) of
		{undefined, Req2} ->
			{no, Req2};
		{<<>>, Req2} ->
			{no, Req2};
		{Cook, Req2} ->
			case mmchat_data:get_cookie(Cook) of
				{ok, Mid} ->
					{ok, Mid, Cook, Req2};
				no ->
					{no, Req2}
			end
	end.	

% check_session(Req) ->
% 	case get_cookie(Req) of
% 		{no, Req2} ->
% 			{no, Req2};
% 		{Cook, Req2} ->
% 			case mmchat_data:check_cookie(Cook) of
% 				ok ->
% 					ok;
% 				no ->
% 					{no, Req2}
% 			end
% 	end.