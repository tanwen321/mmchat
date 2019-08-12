%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(mmchat_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.
start(_Type, _Args) ->
%	mmchat_deps:ensure(),
%	mmchat_deps:local_path(["priv", "www"]),
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, mmchat, "index.html"}},
			{"/favicon.ico", cowboy_static, {priv_file, mmchat, "favicon.ico"}},
			{"/mmchat_socket", mmchat_handler, []},
			{"/login.html", mmchat_web, []},
			{"/chat.html", mmchat_web, []},
			{"/js/[...]", cowboy_static, {priv_dir, mmchat, "js"}},
			{"/css/[...]", cowboy_static, {priv_dir, mmchat, "css"}},
			{"/img/[...]", cowboy_static, {priv_dir, mmchat, "img"}},
			{"/font_Icon/[...]", cowboy_static, {priv_dir, mmchat, "font_Icon"}},
			{"/font_Icon/[...]", cowboy_static, {priv_dir, mmchat, "font_Icon"}},
			{"/emoji-png/[...]", cowboy_static, {priv_dir, mmchat, "emoji-png"}},
			{"/png_tmp/[...]", cowboy_static, {priv_dir, mmchat, "png_tmp"}},
			{"/[...]", mmchat_web, []}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port, 9999}],
		[{env, [{dispatch, Dispatch}]}]),
	mmchat_data:start(),
	mmchat_server:start(),
	mmchat_sup:start_link().

stop(_State) ->
	ok.
