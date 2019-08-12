-module(mmchat_lib).

-export([escape_utf8/1, unescape_utf8/1, stoken/2, priv_path/0, make_cookie/1]).


-type unichar_low() :: 0..16#d7ff.
-type unichar_high() :: 16#e000..16#10ffff.
-type unichar() :: unichar_low() | unichar_high().

escape_utf8(L) when erlang:is_list(L)->
  L2 = bytes_to_codepoints(erlang:list_to_binary(L)),
  escape_utf8(L2, []);

escape_utf8(L) when erlang:is_binary(L)->
  L2 = bytes_to_codepoints(L),
  escape_utf8(L2, []);

escape_utf8(L) ->
  L.

escape_utf8([], L) ->
 lists:reverse(L); 

escape_utf8([H|T], L) ->
  H2 = if H > 255 -> make_utf8(H);
          true -> H
        end,
  escape_utf8(T, [H2|L]).

make_utf8(H) when erlang:is_integer(H) ->
  "%u" ++ erlang:integer_to_list(H,16).

unescape_utf8(L) when erlang:is_list(L) ->
  L2 = string:tokens(L, "%"),
  unescape_utf8(L2, []);
unescape_utf8(L) when erlang:is_binary(L) ->
  L2 = erlang:binary_to_list(L),
  unescape_utf8(L2).

unescape_utf8([], L) ->
   lists:concat(lists:reverse(L));

unescape_utf8([H|T], L) ->
  H3 = case H of
      [$u|H2] ->
        try
          erlang:binary_to_list(codepoints_to_bytes([erlang:list_to_integer(H2, 16)]))
        catch
          _:_ ->
            H
        end;
      _ ->
        H
    end,
  unescape_utf8(T, [H3|L]).



-spec codepoint_to_bytes(unichar()) -> binary().
%% @doc Convert a unicode codepoint to UTF-8 bytes.
codepoint_to_bytes(C) when (C >= 16#00 andalso C =< 16#7f) ->
    %% U+0000 - U+007F - 7 bits
    <<C>>;
codepoint_to_bytes(C) when (C >= 16#080 andalso C =< 16#07FF) ->
    %% U+0080 - U+07FF - 11 bits
    <<0:5, B1:5, B0:6>> = <<C:16>>,
    <<2#110:3, B1:5,
      2#10:2, B0:6>>;
codepoint_to_bytes(C) when (C >= 16#0800 andalso C =< 16#FFFF) andalso
                           (C < 16#D800 orelse C > 16#DFFF) ->
    %% U+0800 - U+FFFF - 16 bits (excluding UTC-16 surrogate code points)
    <<B2:4, B1:6, B0:6>> = <<C:16>>,
    <<2#1110:4, B2:4,
      2#10:2, B1:6,
      2#10:2, B0:6>>;
codepoint_to_bytes(C) when (C >= 16#010000 andalso C =< 16#10FFFF) ->
    %% U+10000 - U+10FFFF - 21 bits
    <<0:3, B3:3, B2:6, B1:6, B0:6>> = <<C:24>>,
    <<2#11110:5, B3:3,
      2#10:2, B2:6,
      2#10:2, B1:6,
      2#10:2, B0:6>>.

-spec codepoints_to_bytes([unichar()]) -> binary().
%% @doc Convert a list of codepoints to a UTF-8 binary.
codepoints_to_bytes(L) ->
    <<<<(codepoint_to_bytes(C))/binary>> || C <- L>>.


-spec codepoint_foldl(fun((unichar(), _) -> _), _, binary()) -> _.
codepoint_foldl(F, Acc, <<>>) when is_function(F, 2) ->
    Acc;
codepoint_foldl(F, Acc, Bin) ->
    {C, _, Rest} = read_codepoint(Bin),
    codepoint_foldl(F, F(C, Acc), Rest).

-spec bytes_to_codepoints(binary()) -> [unichar()].
bytes_to_codepoints(B) ->
    lists:reverse(codepoint_foldl(fun (C, Acc) -> [C | Acc] end, [], B)).

-spec read_codepoint(binary()) -> {unichar(), binary(), binary()}.
read_codepoint(Bin = <<2#0:1, C:7, Rest/binary>>) ->
    %% U+0000 - U+007F - 7 bits
    <<B:1/binary, _/binary>> = Bin,
    {C, B, Rest};
read_codepoint(Bin = <<2#110:3, B1:5,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+0080 - U+07FF - 11 bits
    case <<B1:5, B0:6>> of
        <<C:11>> when C >= 16#80 ->
            <<B:2/binary, _/binary>> = Bin,
            {C, B, Rest}
    end;
read_codepoint(Bin = <<2#1110:4, B2:4,
                       2#10:2, B1:6,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+0800 - U+FFFF - 16 bits (excluding UTC-16 surrogate code points)
    case <<B2:4, B1:6, B0:6>> of
        <<C:16>> when (C >= 16#0800 andalso C =< 16#FFFF) andalso
                      (C < 16#D800 orelse C > 16#DFFF) ->
            <<B:3/binary, _/binary>> = Bin,
            {C, B, Rest}
    end;
read_codepoint(Bin = <<2#11110:5, B3:3,
                       2#10:2, B2:6,
                       2#10:2, B1:6,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+10000 - U+10FFFF - 21 bits
    case <<B3:3, B2:6, B1:6, B0:6>> of
        <<C:21>> when (C >= 16#010000 andalso C =< 16#10FFFF) ->
            <<B:4/binary, _/binary>> = Bin,
            {C, B, Rest}
    end.

priv_path() ->
  {ok, Path} = file:get_cwd(),
  priv_path(Path, []).

priv_path([$p,$r,$i,$v], L) ->
  lists:reverse([$v,$i,$r,$p|L]);
priv_path([$p,$r,$i,$v,$/|_T], L) ->
  lists:reverse([$v,$i,$r,$p|L]);
priv_path([], L) ->
  lists:reverse([$v,$i,$r,$p,$/|L]);
priv_path([H|T], L) ->
  priv_path(T, [H|L]).

stoken(L, N) when is_binary(L) ->
  stoken(erlang:binary_to_list(L), N);
stoken(L, N) ->
  {A, B} = stoken(L, N, []),
  {C, D} = stoken(B, N, []),
  {A, C, D}.

stoken([], _N, L) ->
  lists:reverse(L);
stoken([N|T], N, L) ->
  {lists:reverse(L), T};
stoken([H|T], N, L) ->
  stoken(T, N, [H|L]).

make_cookie(Name) ->
  <<A:64,_C:32>> = crypto:strong_rand_bytes(12),
  D = erlang:integer_to_binary(A),
  <<Name/binary, D/binary>>.