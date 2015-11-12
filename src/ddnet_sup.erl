%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 17:04
%%%-------------------------------------------------------------------
-module(ddnet_sup).
-author("wanghaohao").

-behaviour(supervisor).

%% API
-export([start/1, start_link/0]).

%% callback
-export([init/1]).

start(TopSup) ->
  supervisor:start_child(TopSup, {?MODULE, {?MODULE, start_link, []},
      transient, infinity, supervisor, [?MODULE]}).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).


init([]) ->
  Strategy = {one_for_one, 5, 10},
  {ok, {Strategy, []}}.



