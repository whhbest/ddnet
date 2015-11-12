%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 21:49
%%%-------------------------------------------------------------------
-module(ddnet_client_sup).
-author("wanghaohao").

-behaviour(supervisor).
%% API
-export([start/2, start_link/1]).

-export([init/1]).

start(Parent, Mod) ->
  supervisor:start_child(Parent, {?MODULE, {?MODULE, start_link, [Mod]},
    transient, infinity, supervisor, [?MODULE]}).

start_link(Mod) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Mod]).

init([Mod]) ->
  Child ={ddnet_client,
    {ddnet_client, start, [Mod]},
    temporary, 30000, worker,
    [ddnet_client]},
  {ok,{{simple_one_for_one,10,10}, [Child]}}.