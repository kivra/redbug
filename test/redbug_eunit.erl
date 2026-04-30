-module('redbug_eunit').
-author('mats cronqvist').

-dialyzer(no_improper_lists).

-include_lib("eunit/include/eunit.hrl").

t_0_test() ->
  Filename = "redbug0.txt",
  {_, _, _} = redbug:start("lists:sort", [{print_file, Filename}, print_msec, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  TS = re:split(get_line_seg(Filename, 1, 2), "[:.]"),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual(4,
               length(TS)),
  ?assertEqual(3,
               size(lists:last(TS))),
  maybe_delete(Filename).

t_01_test() ->
  Filename = "redbug01.txt",
  {_, _, _} = redbug:start("lists:sort", [{print_file, Filename}, arity, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort/1">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual(3,
               length(re:split(get_line_seg(Filename, 1, 2), "[:.]"))),
  maybe_delete(Filename).

t_02_test() ->
  Filename = "redbug02.txt",
  {_, _, _} = redbug:start("lists:sort", [{print_file, Filename}, {print_time_unit, microsecond}, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  TS = re:split(get_line_seg(Filename, 1, 2),"[:.]"),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual(4,
               length(TS)),
  ?assertEqual(6,
               size(lists:last(TS))),
  maybe_delete(Filename).

t_1_test() ->
  Filename = "redbug1.txt",
  {_, _, _} = redbug:start("lists:sort->return", [{print_file, Filename}, buffered, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual([<<"lists:sort/1">>, <<"->">>, <<"[1,2,3]">>],
               get_line_seg(Filename, 4, 2, 4)),
  maybe_delete(Filename).

t_2_test() ->
  Filename = "redbug2.txt",
  {_, _, _} = redbug:start("lists:sort->stack", [{print_file, Filename}, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  Lines = lists:seq(3, lines(Filename)-1),
  ?assertEqual([true],
               lists:usort([is_mfa(get_line_seg(Filename, L, 2))||L<-Lines])),
  maybe_delete(Filename).

t_3_test() ->
  Filename = "redbug3.txt",
  Pid = spawn(fun()->receive P when is_pid(P)->P!ding;quit->ok end end),
  {_, _, _} = redbug:start(send, [{procs, Pid}, {print_file, Filename}, debug]),
  Pid ! self(),
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  ?assertEqual(<<"ding">>,
               get_line_seg(Filename, 2, 4)),
  maybe_delete(Filename).

t_4_test() ->
  Filename = "redbug4.txt",
  Pid = spawn(fun()->receive P when is_pid(P)->P!ding;quit->ok end end),
  {_, _, _} = redbug:start('receive', [{procs, Pid}, {print_file, Filename}, debug]),
  Pid ! pling,
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100),
  maybe_show(Filename),
  ?assertEqual(<<"pling">>,
               get_line_seg(Filename, 2, 3)),
  maybe_delete(Filename).

t_5_test() ->
  Filename = "redbug5.txt",
  {_, _, _} = redbug:start("lists:sort->time", [{print_file, Filename}, {time, 999}, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(1100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual(<<"lists:sort/1">>,
               get_line_seg(Filename, 3, 8)),
  maybe_delete(Filename).

t_6_test() ->
  Filename = "redbug6.txt",
  {_, _, _} = redbug:start("lists:sort->count", [{print_file, Filename}, {time, 999}, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(1100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual(<<"lists:sort/1">>,
               get_line_seg(Filename, 3, 4)),
  maybe_delete(Filename).

t_7_test() ->
  Os = [blocking, {time, 999}, {msgs, 1000}, arity, debug],
  {timeout, Msgs} = redbug:start(["erlang:demonitor", "erlang:monitor"], Os),
  ?assertEqual([{erlang, demonitor, 1},
                {erlang, monitor, 2}],
               [MFA || {call, {MFA, _}, _, _} <- Msgs]).

t_8_test() ->
  {_, _, _} = redbug:start("lists:sort->return", [{file, "foo"}, {time, 999}, debug]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(1100),
  {2, Msgs} = replay_trc:go("foo0.trc", fun(E, A) -> [E]++A end, []),
  ?assertEqual(sort,
               e(2, e(4, e(1, Msgs)))),
  ?assertEqual(sort,
               e(2, e(4, e(2, Msgs)))),
  maybe_delete("foo0.trc").

t_9_test() ->
  Filename = "redbug9.txt",
  Options = [{print_file, Filename}, {time, 999}, {print_return, false}],
  {_, _, _} = redbug:start("lists:sort->return", [debug|Options]),
  [1, 2, 3] = lists:sort([3, 2, 1]),
  timer:sleep(1100),
  maybe_show(Filename),
  ?assertEqual(<<"lists:sort([3,2,1])">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual([<<"lists:sort/1">>, <<"->">>, <<"'...'">>],
               get_line_seg(Filename, 4, 2, 4)),
  maybe_delete(Filename).

t_10_test() ->
  Filename = "redbug10.txt",
  Options = [{print_file, Filename}, {time, 999}],
  {_, _, _} = redbug:start("redbug_eunit:ipl()->return", [debug|Options]),
  ipl(),
  timer:sleep(1100),
  maybe_show(Filename),
  ?assertEqual(<<"redbug_eunit:ipl()">>,
               get_line_seg(Filename, 2, 2)),
  ?assertEqual([<<"redbug_eunit:ipl/0">>, <<"->">>, <<"[a,b|c]">>],
               get_line_seg(Filename, 4, 2, 4)),
  maybe_delete(Filename).

%% test printing of improper lists
ipl() -> [a, b|c].

loct_stripped_non_arity_return_test() ->
  M = load_stripped_module(),
  redbug_start(?FUNCTION_NAME, "stripped_mod:local_fun->return", []),
  M:exported_fun(5),
  redbug_normal_stop(),
  unload_module(M),
  Content = redbug_output(?FUNCTION_NAME),
  ?assertEqual(<<"stripped_mod:local_fun(5)">>,
               get_line_seg(Content, 2, 2)),
  ?assertEqual([<<"stripped_mod:local_fun/1">>, <<"->">>, <<"10">>],
               get_line_seg(Content, 4, 2, 4)).

loct_stripped_full_module_return_test() ->
  M = load_stripped_module(),
  redbug_start(?FUNCTION_NAME, "stripped_mod->return", []),
  M:exported_fun(5),
  redbug_normal_stop(),
  unload_module(M),
  Content = redbug_output(?FUNCTION_NAME),
  ?assertEqual(<<"stripped_mod:local_fun(5)">>,
               get_line_seg(Content, 4, 2)),
  ?assertEqual([<<"stripped_mod:local_fun/1">>, <<"->">>, <<"10">>],
               get_line_seg(Content, 6, 2, 4)).

loct_stripped_non_arity_count_test() ->
  M = load_stripped_module(),
  redbug_start(?FUNCTION_NAME, "stripped_mod:local_fun->count", [{time, 999}]),
  M:exported_fun(5),
  redbug_timeout_stop(),
  unload_module(M),
  Content = redbug_output(?FUNCTION_NAME),
  ?assertEqual(<<"stripped_mod:local_fun(5)">>,
               get_line_seg(Content, 2, 2)),
  ?assertEqual(<<"stripped_mod:local_fun/1">>,
               get_line_seg(Content, 3, 4)).

loct_stripped_full_module_count_test() ->
  M = load_stripped_module(),
  redbug_start(?FUNCTION_NAME, "stripped_mod->count", [{time, 999}]),
  M:exported_fun(5),
  redbug_timeout_stop(),
  unload_module(M),
  Content = redbug_output(?FUNCTION_NAME),
  ?assertEqual(<<"stripped_mod:local_fun(5)">>,
               get_line_seg(Content, 4, 2)),
  ?assertEqual(<<"stripped_mod:local_fun/1">>,
               get_line_seg(Content, 5, 4)).

load_stripped_module() ->
  TestCode =
        "-module(stripped_mod)."
        "-export([exported_fun/1])."
        "exported_fun(X) -> local_fun(X)."
        "local_fun(X) -> X*2.",
  Opts = [determenistic, no_line_info],

  {ok, stripped_mod, Bin} = compile_str(TestCode, Opts),
  {ok, {stripped_mod, StrippedBin}} = beam_lib:strip(Bin),
  TmpFile = write_beam(stripped_mod, StrippedBin),

  %% Verify beam_lib:strip does compressing
  %% 16#1f8b: gzip magic numbers
  %% 16#08: Compression method: deflate
  <<16#1f, 16#8b, 16#08, _/binary>> = StrippedBin,
  %% verify LocT is actually gone
  {error, beam_lib, _} = beam_lib:chunks(StrippedBin, [locals]),
  {module, stripped_mod} = code:load_binary(stripped_mod, TmpFile, StrippedBin),
  stripped_mod.

compile_str(Str, Opts) ->
    Lines = string:split(Str, ".", all),
    Forms = lists:reverse(forms_from_string(Lines, [])),
    compile:forms(Forms, Opts).

forms_from_string([], Acc) ->
    Acc;
forms_from_string([[]|Lines], Acc) ->
    forms_from_string(Lines, Acc);
forms_from_string([L|Lines], Acc) ->
    {ok, T, _} = erl_scan:string(L ++ [$.]),
    {ok, F} = erl_parse:parse_form(T),
    forms_from_string(Lines, [F|Acc]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% trace file utilities

output_filename(Name) ->
    filename(Name, ".txt").

beam_filename(Name) ->
    filename(Name, ".beam").

filename(Name, Ext) ->
  atom_to_list(Name) ++ Ext.

redbug_start(TestName, TraceFun, TraceOpts) ->
  Filename = output_filename(TestName),
  Options = [{print_file, Filename}, debug|TraceOpts],
  {_, _, _} = redbug:start(TraceFun, Options).

redbug_normal_stop() ->
  timer:sleep(100),
  redbug:stop(),
  timer:sleep(100).

redbug_timeout_stop() ->
  timer:sleep(1100).

write_beam(M, Bin) ->
  TmpDir = filename:dirname(code:which(redbug_eunit)),
  TmpFile = filename:join(TmpDir, beam_filename(M)),
  ok = file:write_file(TmpFile, Bin),
  {module, M} = code:load_abs(filename:rootname(TmpFile)),
  TmpFile.

unload_module(M) ->
  TmpDir = filename:dirname(code:which(redbug_eunit)),
  TmpFile = filename:join(TmpDir, beam_filename(M)),
  ok = file:delete(TmpFile),
  code:purge(M).

redbug_output(Name) ->
  Filename = output_filename(Name),
  Content = read_file(Filename),
  maybe_show(Content),
  maybe_delete(Filename),
  Content.

maybe_show(Filename) when is_list(Filename) ->
  [io:fwrite("~p~n", [read_file(Filename)]) || in_shell()];
maybe_show(Content) ->
  [io:fwrite("~p~n", [Content]) || in_shell()].

lines(Filename) when is_list(Filename) ->
  length(read_file(Filename));
lines(Content) ->
  length(Content).

get_line_seg(Content, Line, Seg) ->
  hd(get_line_seg(Content, Line, Seg, Seg)).

-define(is_string(A), A >= 0, A =< 256).
get_line_seg([A|_] = Filename, Line, SegF, SegL) when ?is_string(A) ->
  [e(S, e(Line, read_file(Filename))) || S <- lists:seq(SegF, SegL)];
get_line_seg(Content, Line, SegF, SegL) ->
  [e(S, e(Line, Content)) || S <- lists:seq(SegF, SegL)].

read_file(Filename) ->
  {ok, C} = file:read_file(Filename),
  [[S||S<-re:split(L, "\s"), S=/=<<>>]||L<-re:split(C, "\n"), L=/=<<>>].

is_mfa(H) ->
  L = byte_size(H),
  {match, [{0, L}]} =:= re:run(H, "[a-zA_Z0-9\'/:_-]*/[0-9]+").

maybe_delete(Filename) ->
  [file:delete(Filename) || not in_shell()].

in_shell() ->
  lists:member("shell:eval_loop/3", stack()).

stack() ->
  stack(self()).

stack(P) ->
  [string:strip(e(2, (string:tokens(L, "(+)")))) || L<- bt(P), $0 =:= hd(L)].

bt(P) ->
  string:tokens(binary_to_list(e(2, (process_info(P, backtrace)))), "\n").

e(N, L) when is_list(L) -> lists:nth(N, L);
e(N, T) when is_tuple(T)-> element(N, T).
