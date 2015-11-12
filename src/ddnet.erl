%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 17:01
%%%-------------------------------------------------------------------
-module(ddnet).
-author("wanghaohao").

-define(NET_SUP, ddnet_sup).

%% API
-export([start/2, stop/1]).

start(TopSup, Mod) ->
  require(?MODULE),
  ddnet_sup:start(TopSup),
  ddnet_client_sup:start(?NET_SUP, Mod),

  Ports = application:get_env(?MODULE, port, 6000),
  lists:foreach(fun(Port)->
    ddnet_listener_sup:start(?NET_SUP, Mod, Port)
  end, Ports).


stop(TopSup) ->
  supervisor:terminate_child(TopSup, ?NET_SUP),
  supervisor:delete_child(TopSup, ?NET_SUP).

require(App) ->
    application:start(App).
