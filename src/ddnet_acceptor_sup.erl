%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 21:22
%%%-------------------------------------------------------------------
-module(ddnet_acceptor_sup).
-author("wanghaohao").

-behaviour(supervisor).
%% API
-export([start_link/1,
        start_acceptors/3]).

-export([init/1]).

start_link(Port) ->
  supervisor:start_link({local, acceptor_sup_name(Port)}, ?MODULE, []).

init([]) ->
  Strategy = {one_for_one, 5, 10},
  {ok, {Strategy, []}}.

acceptor_sup_name(Port) ->
  list_to_atom(lists:concat([?MODULE, Port])).

start_acceptors(Mod, Port, Lsock) ->
  AcceptorNum = application:get_env(dd_net, acceptor_num, 5),
  [begin
     supervisor:start_child(acceptor_sup_name(Port), {{ddnet_acceptor, Seq}, {ddnet_acceptor, start_link, [Mod, Port, Lsock]},
       transient, 10000, worker, [ddnet_acceptor]})
   end || Seq <- lists:seq(1, AcceptorNum)],

  ok.


