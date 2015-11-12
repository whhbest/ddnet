%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十月 2015 14:19
%%%-------------------------------------------------------------------
-module(ddnet_listener_sup).
-author("wanghaohao").

-behaviour(supervisor).

-export([start/3,
        start_link/2]).

%% API
-export([init/1]).

start(Parent, Mod, Port) ->
  supervisor:start_child(Parent, {{?MODULE, Port}, {?MODULE, start_link, [Mod, Port]},
    transient, infinity, supervisor, [?MODULE]}).

start_link(Mod, Port) ->
  supervisor:start_link(?MODULE, [Mod, Port]).

init([Mod, Port]) ->
  Strategy = {one_for_all, 10, 10},
  AcceptorSup = {ddnet_acceptor_sup, {ddnet_acceptor_sup, start_link, [Port]},
    transient, infinity, supervisor, [ddnet_acceptor_sup]},
  Listener = {ddnet_listener, {ddnet_listener, start_link, [Mod, Port, fun onlisten_succ/3, fun onlisten_err/2]},
    transient, 10000, worker, [ddnet_listener]},
  {ok, {Strategy, [AcceptorSup, Listener]}}.

onlisten_succ(Ip, Port, Sock) ->
  io:format("start_listener on ip:~w, port: ~w", [Ip, Port]),
  Sock.

onlisten_err(Port, Reason) ->
  io:format("start_listener failed on port:~w, reason:~w", [Port, Reason]),
  ok.

