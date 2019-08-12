-module(mmchat_web).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

%-define(LOG(X), io:format("{~p,~p}: ~p~n", [?MODULE,?LINE,X])).
-define(LOG(X), ok).

init(_Type, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method,_} = cowboy_req:method(Req),
	{Path, Req2} = cowboy_req:path(Req),
	HasBody = cowboy_req:has_body(Req2),
	{ok, Req3} = case Path of
		<<"/login.html">> ->
			do_login(Method, HasBody, Req2);
		<<"/chat.html">> ->
			do_chat(Method, Req2);
		<<"/get_online_user.html">> ->
			do_get_online(Method, Req2);
		_ ->
			{ok, Index}=file:read_file(mmchat_lib:priv_path() ++ "/index.html"),
			cowboy_req:reply(200, [{<<"content-type">>, <<"text/html">>}], Index, Req2)
	end,
	{ok, Req3, State}.


do_login(<<"POST">>, true, Req) ->
	{ok, PostVals, Req2} = cowboy_req:body_qs(Req),
	Username = proplists:get_value(<<"u">>, PostVals),
	Pass = proplists:get_value(<<"p">>, PostVals),
	do_login_2(Username, Pass, Req2);
do_login(<<"POST">>, fasle, Req) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);
do_login(_, _, Req) ->
	cowboy_req:reply(405, Req).

do_login_2(undefined, _, Req) ->
	cowboy_req:reply(400, [], <<"Missing username.">>, Req);
do_login_2(_, undefined, Req) ->
	cowboy_req:reply(400, [], <<"Missing password.">>, Req);
do_login_2(Username, Pass, Req) ->
	case check_cookie(Req) of
		{ok, Req2} ->
			{ok, Index}=file:read_file(mmchat_lib:priv_path() ++ "/login.html"),
			cowboy_req:reply(200, [{<<"content-type">>, <<"text/html">>}], Index, Req2);
		{no, Req2} ->
			Cook = mmchat_lib:make_cookie(Username),
			{{Ip, _Port}, Req3} = cowboy_req:peer(Req2),
			case mmchat_data:check_passwd(Username, Pass, Cook, Ip) of
				true ->
					Req4 = cowboy_req:set_resp_cookie(<<"mmssid">>, Cook, [{path, <<"/">>}], Req3),
					{ok, Index}=file:read_file(mmchat_lib:priv_path() ++ "/login.html"),
					cowboy_req:reply(200, [{<<"content-type">>, <<"text/html">>}], Index, Req4);
				{no, Error} ->
					?LOG(Error),
					cowboy_req:reply(400, [], Error, Req2)
			end
	end.

do_chat(_, Req) ->
	case check_cookie(Req) of
		{ok, Req2} ->
			{ok, Index}=file:read_file(mmchat_lib:priv_path() ++ "/chat.html"),
			cowboy_req:reply(200, [{<<"content-type">>, <<"text/html">>}], Index, Req2);
		{no, Req2} ->
			cowboy_req:reply(400, [], <<"please login in first">>, Req2)
	end.

do_get_online(<<"GET">>, Req) ->
	Res = mmchat_data:get_online_user(),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/html">>}], Res, Req);
do_get_online(_, Req)->
	cowboy_req:reply(405, Req).

terminate(_Reason, _Req, _State) ->
	ok.

check_cookie(Req) ->
	case cowboy_req:cookie(<<"mmssid">>, Req) of
		{undefined, Req2} ->
			{no, Req2};
		{<<>>, Req2} ->
			{no, Req2};
		{Cook, Req2} ->
			mmchat_data:check_login_cookie(Cook, Req2)
	end.