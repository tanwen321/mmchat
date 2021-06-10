-module(mmchat_data).
-compile(export_all).
%%-export([start/0, insert/2, insert/3]).

-include_lib("stdlib/include/qlc.hrl").

-include("../include/mmchat.hrl").

%-define(LOG(X), io:format("{~p,~p}: ~p~n", [?MODULE,?LINE,X])).
-define(LOG(X), ok).

-define(IMAGES,["./img/tx001.jpg", 
    "./img/tx002.jpg", 
    "./img/tx003.jpg", 
    "./img/tx004.jpg", 
    "./img/tx005.jpg", 
    "./img/tx006.jpg", 
    "./img/tx007.jpg", 
    "./img/tx008.jpg", 
    "./img/tx009.jpg"]).

delete() ->
    mnesia:stop(),
    mnesia:delete_schema([node()]).

start() ->
    case mnesia:system_info(use_dir) of
        true ->
            alread_created;
        _ ->
            mnesia:create_schema([node()])
    end,
    _ = mnesia:start(),
    case lists:member(user_seq, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(user_seq, [{attributes, record_info(fields, user_seq)}, {type,set}, {disc_copies, [node()]}]),
            ok
        end,
    case lists:member(muser, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(muser, [{attributes, record_info(fields, muser)}, {type,set}, {disc_copies, [node()]}]),
            ok
        end,
    case lists:member(ugroup, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(ugroup, [{attributes, record_info(fields, ugroup)}, {type,set}, {disc_copies, [node()]}]),
            _ = mnesia:dirty_update_counter(user_seq, user, 1), 
            Group_init = #ugroup{gid=1, gname="test", gimage="./img/tx008.jpg", gword="everything will be ok"},
           F = fun() ->  
                mnesia:write(Group_init)  
            end,  
            mnesia:transaction(F)
        end,
    case lists:member(muinfo, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(muinfo, [{attributes, record_info(fields, muinfo)}, {type, set}, {ram_copies, [node()]}]),
            ok
        end,
    case lists:member(user_data, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(user_data, [{attributes, record_info(fields, user_data)}, {type, set}, {ram_copies, [node()]}]),
            ok
        end,
    case lists:member(mgroup, mnesia:system_info(tables)) of
        true ->
            ok;
        false ->
            _ = mnesia:create_table(mgroup, [{attributes, record_info(fields, mgroup)}, {type, set}, {ram_copies, [node()]}]),
            ok
        end.

% start() ->
%     mnesia:start(),
%     mnesia:wait_for_tables([muser, user_seq], 20000).

stop() ->
    mnesia:stop().

add_user(User, Passwd, Group) when is_list(User), is_list(Passwd) ->  
    UserId = mnesia:dirty_update_counter(user_seq, user, 1),  
    U_bin = unicode:characters_to_binary(User),
    U_pass = unicode:characters_to_binary(Passwd),
    P_bin = erlang:md5(<<U_bin/binary, U_pass/binary>>),
    User2 = case do(qlc:q([X || X <- mnesia:table(ugroup), X#ugroup.gname == Group])) of
        [] ->
            Id = add_group(Group),
            #muser{mid=UserId, mname=User, uimage=get_image(), passwd=P_bin, group=[Id], createtime=os:timestamp()};
        [Ugroup] ->
            #muser{mid=UserId, mname=User, uimage=get_image(), passwd=P_bin, group=[Ugroup#ugroup.gid], createtime=os:timestamp()}
    end,
    F = fun() ->  
        mnesia:write(User2)  
    end,  
    mnesia:transaction(F),  
    ok.

add_user(User, Passwd) when is_list(User), is_list(Passwd) -> 
    add_user(unicode:characters_to_binary(User), unicode:characters_to_binary(Passwd));
add_user(User, Passwd) when is_binary(User), is_binary(Passwd) -> 
    UserId = mnesia:dirty_update_counter(user_seq, user, 1), 
    P_bin = erlang:md5(<<User/binary, Passwd/binary>>),
    User2 = #muser{mid=UserId, mname=erlang:binary_to_list(User), uimage=get_image(), passwd=P_bin, group=[1], createtime=os:timestamp()},  
    F = fun() ->  
        mnesia:write(User2)  
    end,  
    mnesia:transaction(F),  
    ok. 

add_group(Group) ->
    Uid = mnesia:dirty_update_counter(user_seq, user, 1),
    Ng = #ugroup{gid=Uid, gname=Group, gimage=get_image(), gword=Group, gcretime=os:timestamp()},
    F = fun() ->  
        mnesia:write(Ng)  
    end,  
    mnesia:transaction(F),  
    Ng.

add_group(Group, Iurl, Word) ->
    Uid = mnesia:dirty_update_counter(user_seq, user, 1),
    Ng = #ugroup{gid=Uid, gname=Group, gimage=Iurl, gword=Word, gcretime=os:timestamp()},
    F = fun() ->  
        mnesia:write(Ng)  
    end,  
    mnesia:transaction(F),  
    Ng.

get_cookie(Cookie) ->
    case do(qlc:q([X || X <- mnesia:table(muinfo), X#muinfo.mcook == Cookie])) of
        [] ->
            no;
        [Minfo] ->
            {ok, Minfo#muinfo.mid}
    end.

check_passwd(User, Passwd, Cook, Ip) when is_list(User), is_list(Passwd) ->
    check_passwd(unicode:characters_to_binary(User), is_list(Passwd), Cook, Ip);
check_passwd(User, Passwd, Cook, Ip) when is_binary(User), is_binary(Passwd) ->
    ?LOG({User, Passwd, Cook, Ip}),
    Ulist = erlang:binary_to_list(User),
    P_bin = erlang:md5(<<User/binary, Passwd/binary>>),
    case do(qlc:q([X || X <- mnesia:table(muser), X#muser.mname == Ulist])) of
        [] -> {no, <<"no user.">>};
        [Muser] ->
            Passwd_2 = Muser#muser.passwd,
            if Passwd_2 == P_bin ->
                case ets:lookup(muinfo, Muser#muser.mid) of
                    [] -> 
                        {A, B, _C} = os:timestamp(),
                        _ = ets:insert(muinfo, #muinfo{mid=Muser#muser.mid, mip=Ip, matime={A, B}, mcook=Cook}),
                        true;
                    [Muinfo] ->
                        case check_info(Muinfo) of
                            true ->
                                {A, B, _C} = os:timestamp(),
                                _ = ets:insert(muinfo, Muinfo#muinfo{mip=Ip, matime={A, B}, mcook=Cook}),
                                true;
                            {no, E} ->
                              {no, E}
                        end
                end;
            true -> 
                {no, <<"wrong passwd.">>}
            end
    end.

check_info(#muinfo{mpid=Pid}) ->
    if Pid == undefined ->
        true;
    true ->
        case erlang:is_process_alive(Pid) of
            false ->
                true;
            true ->
                {no, <<"user had login.">>}
        end
    end.

check_login_cookie(Cook, Req) ->
    ?LOG(Cook),
    case cowboy_req:peer(Req) of
        {{Ip, _Port}, Req2} ->
            ?LOG(Ip),
            case do(qlc:q([X || X <- mnesia:table(muinfo), X#muinfo.mcook == Cook])) of
                [Minfo] ->
                    case diff_user_now(Minfo, Ip) of
                        ok ->                            
                            {ok, Req2};
                        no ->                            
                            {no, Req2}
                    end;
                [] ->
                    ?LOG("23213131"),
                    {no, Req2}
            end;
        _E ->
            ?LOG(_E),
            {no, Req}
    end.

init_data(Pid, Uid) ->
    case erlang:is_process_alive(Pid) of
        true ->
            [Muser] = mnesia:dirty_read(muser, Uid),
            [Uinfo] = ets:lookup(muinfo, Uid),
            ets:insert(muinfo, Uinfo#muinfo{mpid=Pid}),
            add_groupuser(Muser#muser.group, Pid),
            S_info = {[{<<"id">>, erlang:integer_to_binary(Uid)},
              {<<"na">>, unicode:characters_to_binary(Muser#muser.mname)},
              {<<"im">>, unicode:characters_to_binary(Muser#muser.uimage)},
              {<<"ti">>, get_time1()},
              {<<"wo">>, unicode:characters_to_binary(Muser#muser.mword)}]},
            send_user_init(Pid, Muser#muser.group, Muser#muser.friend, S_info);
        false ->
            []
    end.

add_groupuser([], _) ->
    ok;
add_groupuser([H|T], Pid) ->
    case ets:lookup(mgroup, H) of
        [Glist] ->
            ets:insert(mgroup, Glist#mgroup{gulist=[Pid|Glist#mgroup.gulist]});
        [] ->
            ets:insert(mgroup, #mgroup{gname=H, gulist=[Pid]})
    end,
    add_groupuser(T, Pid).


adduser_to_group(User, Gname) ->
    case do(qlc:q([X || X <- mnesia:table(muser), X#muser.mname == User])) of
        [Muser] ->
            case do(qlc:q([X || X <- mnesia:table(ugroup), X#ugroup.gname == Gname])) of
                [Ugroup] ->
                    G_list = lists:reverse([Ugroup#ugroup.gid|Muser#muser.group]),
                    New = Muser#muser{group = G_list},
                    F = fun() ->  
                        mnesia:write(New)  
                    end,  
                    mnesia:transaction(F);
                [] ->
                    ok
            end;
        [] ->
            ok
    end.

add_friends(User1, User2) ->
    case do(qlc:q([X || X <- mnesia:table(muser), X#muser.mname == User1])) of
        [Muser1] ->
            case do(qlc:q([X || X <- mnesia:table(muser), X#muser.mname == User2])) of
                [Muser2] ->
                    Nl1 = [Muser2#muser.mid|Muser1#muser.friend],
                    Nl2 = [Muser1#muser.mid|Muser2#muser.friend],
                    New1 = Muser1#muser{friend = Nl1},
                    New2 = Muser2#muser{friend = Nl2},
                    F = fun() ->  
                        mnesia:write(New1),
                        mnesia:write(New2) 
                    end,  
                    mnesia:transaction(F);
                [] ->
                    ok
            end;
        [] ->
            ok
    end.

send_user_init(Pid, Glist, Flist, S_info) ->
    G_info = group_info(Glist, []),
    F_info = friend_info(Flist, S_info, []),
    Pid ! {init, jiffy:encode({[{<<"gr">>, [S_info|G_info ++ F_info]}]})}.

group_info([], L) ->
    lists:reverse(L);
    % jiffy:encode({[{<<"gr">>, L2}]});
group_info([H|T], L) ->
    case mnesia:dirty_read(ugroup, H) of
        [Ugroup] ->
            M = {[{<<"id">>, erlang:integer_to_binary(H)},
                  {<<"na">>, unicode:characters_to_binary(Ugroup#ugroup.gname)},
                  {<<"im">>, unicode:characters_to_binary(Ugroup#ugroup.gimage)},
                  {<<"ti">>, get_time1()},
                  {<<"wo">>, unicode:characters_to_binary(Ugroup#ugroup.gword)}]},
            group_info(T, [M|L]);
        [] ->
            group_info(T, L)
    end.

friend_info([], _S_info, L) ->
    lists:reverse(L);
friend_info([H|T], S_info, L) ->
    ?LOG({[H|T], S_info, L}),
    case ets:lookup(muinfo, H) of
        [Minfo] ->
            case Minfo#muinfo.mpid =/= undefined andalso erlang:is_process_alive(Minfo#muinfo.mpid) of
                false ->
                    [];
                true ->
                    Minfo#muinfo.mpid ! {init, jiffy:encode({[{<<"gr">>, [S_info]}]})},
					case mnesia:dirty_read(muser, H) of
						[Muser] ->
							M = {[{<<"id">>, erlang:integer_to_binary(H)},
								  {<<"na">>, unicode:characters_to_binary(Muser#muser.mname)},
								  {<<"im">>, unicode:characters_to_binary(Muser#muser.uimage)},
                                  {<<"ti">>, get_time1()},
								  {<<"wo">>, unicode:characters_to_binary(Muser#muser.mword)}]},
								   friend_info(T, S_info, [M|L]);
						[] ->
							friend_info(T, S_info, L)
					end
            end;
        [] ->
            friend_info(T, S_info, L)
    end.

send_group_msg(Pid, Uid, Msg) ->
    case mmchat_lib:stoken(Msg, $@) of
        {Gid, "3", Msg2} ->
            Id =erlang:list_to_integer(Gid),
            Bin = unicode:characters_to_binary(get_imagename(Msg2)),
            ?LOG(Bin),
            case mnesia:dirty_read(muser, Id) of
                [_Muser] ->
                    send_friend_msg(Id, Uid, "3", Bin);
                [] ->
                    send_group_msg(Id, Pid, Uid, "3", Bin)
            end;            
        {Gid, Type, Msg2} ->
            ?LOG({Gid, Type, Msg2}),
            Id =erlang:list_to_integer(Gid),
            Bin = iolist_to_binary(Msg2),
            case mnesia:dirty_read(muser, Id) of
                [_Muser] ->
                    send_friend_msg(Id, Uid, Type, Bin);
                [] ->
                    send_group_msg(Id, Pid, Uid, Type, Bin)
            end;
        _E ->
            ?LOG(_E),
            ok
    end.

send_group_msg(Id, Pid, Uid, Type, Bin) ->
    [Muser] = mnesia:dirty_read(muser, Uid),
    M = jiffy:encode({[{<<"id">>, erlang:integer_to_binary(Id)}, {<<"fn">>, unicode:characters_to_binary(Muser#muser.mname)}, {<<"fi">>, unicode:characters_to_binary(Muser#muser.uimage)}, {<<"ty">>, unicode:characters_to_binary(Type)}, {<<"ti">>, get_time1()}, {<<"da">>, Bin}]}),
    case ets:lookup(mgroup, Id) of
        [Mgroup] ->
            [ X ! M || X<- Mgroup#mgroup.gulist, X =/= Pid],
            ok;
        [] ->
            ok
    end.

send_friend_msg(Id, Uid, Type, Bin) ->
    [Muser] = mnesia:dirty_read(muser, Uid),
    M = jiffy:encode({[{<<"id">>, erlang:integer_to_binary(Uid)}, {<<"fn">>, unicode:characters_to_binary(Muser#muser.mname)}, {<<"fi">>, unicode:characters_to_binary(Muser#muser.uimage)}, {<<"ty">>, unicode:characters_to_binary(Type)}, {<<"ti">>, get_time1()}, {<<"da">>, Bin}]}),
    case ets:lookup(muinfo, Id) of
        [Muinfo] ->
            case Muinfo#muinfo.mpid =/= undefined andalso erlang:is_process_alive(Muinfo#muinfo.mpid) of
                true ->
                    Muinfo#muinfo.mpid ! M;
                false ->
                    []
            end;
        [] ->
            ok
    end.

out_sock(Pid) ->
    ?LOG(Pid),
    case do(qlc:q([X || X <- mnesia:table(muinfo), X#muinfo.mpid == Pid])) of
        [Uinfo] ->
            [Muser] = mnesia:dirty_read(muser, Uinfo#muinfo.mid),
            send_exit_msg(Muser#muser.mid, Muser#muser.friend),
            del_groupuser(Muser#muser.group, Pid),
            ets:insert(muinfo, Uinfo#muinfo{mpid=undefined}),
            ok;
        [] ->
            ok
    end.

send_exit_msg(_, []) ->
    ok;
send_exit_msg(Id, [H|T]) ->
    ?LOG({Id, [H|T]}),
    case ets:lookup(muinfo, H) of
        [] ->
            [];
        [Minfo] ->
            case Minfo#muinfo.mpid =/= undefined andalso erlang:is_process_alive(Minfo#muinfo.mpid) of
                true ->
                    Minfo#muinfo.mpid ! {init, jiffy:encode({[{<<"fe">>, erlang:integer_to_binary(Id)}]})};
                false ->
                    []
            end
    end,
    send_exit_msg(Id, T).

del_groupuser([], _) ->
    ok;
del_groupuser([H|T], Pid) ->
    case ets:lookup(mgroup, H) of
        [Glist] ->
            List = Glist#mgroup.gulist -- [Pid],
            ets:insert(mgroup, Glist#mgroup{gulist=List});
        [] ->
            ok
    end,
    add_groupuser(T, Pid).

% get_group(Pid) ->
%     case do(qlc:q([X || X <- mnesia:table(muinfo), X#muinfo.mpid == Pid])) of
%         [Uinfo] ->
%             [Muser] = mnesia:dirty_read(muser, Uinfo#muinfo.mid),
%             {ok, Uinfo#muinfo.group};
%         [] ->
%             {ok, [1]}
%     end.

show_user() ->
    do(qlc:q([X || X <- mnesia:table(muser)])).

show_group() ->
    do(qlc:q([X || X <- mnesia:table(ugroup)])).

update(User) ->
    F = fun() ->
        mnesia:write(User)
    end,
    mnesia:transaction(F).

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

get_image() ->
    N = erlang:length(?IMAGES),
    M = erlang:trunc(rand:uniform() * N+1),
    lists:nth(M, ?IMAGES).

get_time1() ->
    {{Y, M, D},{H,Mi,_}} = calendar:now_to_local_time(os:timestamp()),
    T = lists:flatten(io_lib:format("~w-~2..0w-~2..0w-~w-~2..0w",[Y, M, D, H, Mi])),
    unicode:characters_to_binary(T).

get_time2() ->
    {{_,M,D},{H,Mi,_}} = calendar:now_to_local_time(os:timestamp()),
    T = if H > 12 ->
        lists:flatten(io_lib:format("~2..0w-~2..0w, ~w:~2..0w PM",[M, D, H-12, Mi]));
    true ->
        lists:flatten(io_lib:format("~2..0w-~2..0w, ~w:~2..0w AM",[M, D, H, Mi]))
    end,
    unicode:characters_to_binary(T).

get_online_user() ->
    L  = ets:tab2list(muinfo),
    make_res(L, []).

make_res([], L) ->
    jiffy:encode({[{<<"res">>,[{L}]}]});
make_res([#muinfo{mid=Id}|T], L) ->
    [Muser] = mnesia:dirty_read(muser, Id),
    make_res(T, [{<<"name">>, unicode:characters_to_binary(Muser#muser.mname)}|L]).

get_imagename(Msg2) when erlang:is_list(Msg2)->
    get_imagename(unicode:characters_to_binary(Msg2));
get_imagename(Msg2) ->
    case ets:lookup(user_data, erlang:md5(Msg2)) of
        [] ->
            save_image(Msg2);
        [Ud = #user_data{ifname = Name}] ->
            _ = ets:insert(user_data, Ud#user_data{utime=os:timestamp()}),
            Name
    end.

save_image(Msg2) ->
    {_, B, C} = os:timestamp(),
    case get_imgtype(Msg2) of
        no ->
            ?ERRORFILE;
        {Itype, Bin} ->
            ?LOG(Itype),
            Filename = lists:flatten(io_lib:format("/png_tmp/~p~p.~s",[B, C, Itype])),
            case save_image(Bin, Filename) of
                no ->
                    ?ERRORFILE;
                Fname ->
                    _ = ets:insert(user_data, #user_data{imid=erlang:md5(Msg2), ifname=Fname, utime=os:timestamp()}),
                    Fname
            end
    end.   

save_image(T, Filename) ->
    Bin = base64:decode(T),
    ?LOG(mmchat_lib:priv_path() ++ Filename),
    case file:write_file(mmchat_lib:priv_path() ++ Filename, Bin) of
        ok ->
            [$.|Filename];
        _ ->
            no
    end.

get_imgtype(<<"data:image/", Bin/binary>>) ->
    get_imgtype(Bin,[]);
get_imgtype(_) ->
    no.

get_imgtype(<<59, B/binary>>, L) ->
    if erlang:length(L) > ?MAXFLEN ->
        no;
    true ->
        case B of
            <<"base64,", Bin/binary>> ->
                {lists:reverse(L), Bin};
            _ ->
                no
        end
    end;
get_imgtype(<<A, B/binary>>, L) ->
    get_imgtype(B, [A|L]).

diff_user_now(Minfo, Ip) ->
    if Minfo#muinfo.mip == Ip ->
        {A, B, _} = os:timestamp(),
        {A1, B1} = Minfo#muinfo.matime,
        D_time = (A-A1) * 1000000 + (B-B1),
        if D_time < ?MAXTIME ->
            _ = ets:insert(muinfo, Minfo#muinfo{matime={A,B}}),
            ok;
        true ->
            ets:delete(muinfo, Minfo#muinfo.mid),
            no
        end;
    true ->
        no
    end.