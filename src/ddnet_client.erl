%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十月 2015 15:20
%%%-------------------------------------------------------------------
-module(ddnet_client).
-author("wanghaohao").

-behaviour(gen_server).
%% API
-export([start/3]).

%% callback
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
        terminate/2, code_change/3]).

-record(state, {mod, port, sock, client_state}).

start(Mod, Port, Sock) ->
%%   io:format("start a client~n", []),
  Opts = [{spawn_opt, [{min_heap_size, 10*1024},{min_bin_vheap_size, 10*1024}]}],
  gen_server:start_link(?MODULE, [Mod, Port, Sock], Opts).

init([Mod, Port, Sock]) ->
  process_flag(trap_exit, true),
  {ok, Cstate} = Mod:init(Sock),
  {ok, #state{mod=Mod, port=Port, sock=Sock, client_state=Cstate}}.

handle_call(_Req, _From, State) ->
  {reply, ok, State}.

handle_cast(start, #state{sock=Sock} = State) ->
%%   io:format("start recv~n", []),
  prim_inet:async_recv(Sock, 0, -1),
  {noreply, State};

handle_cast(_Msg, State) ->
  {noreply, State}.

%% 收到网络数据
handle_info({inet_async, Sock, _Ref, {ok, Data}}, #state{mod=Mod, client_state=Cstate}=State) ->
  case catch Mod:handle_data(Data, Cstate) of
    stop ->
      {stop, normal, State};
    {ok, NewCstate} ->
      prim_inet:async_recv(Sock, 0, -1),
      {noreply, State#state{client_state=NewCstate}};
    {'EXIT', Reason} ->
      Mod:handle_log("error:~p", [Reason]),
      prim_inet:async_recv(Sock, 0, -1),
      {noreply, State};
    _ ->
      prim_inet:async_recv(Sock, 0, -1),
      {noreply, State}
  end;

handle_info({inet_async, _Sock, _Ref, {error, closed}}, #state{mod=Mod, port=Port}=State) ->
  catch Mod:handle_closed({recv_error, closed}, Port),
  {stop, normal, State};

handle_info({inet_async, _Sock, _Ref, {error, Error}}, #state{mod=Mod, port=Port}=State) ->
  catch Mod:handle_closed({recv_error, Error}, Port),
  {stop, normal, State};

handle_info({inet_reply, _Sock, ok}, State) ->
  {noreply, State};

handle_info({inet_reply, _Sock, Res}, #state{mod=Mod, port=Port}=State) ->
  catch Mod:handle_closed({send_error, Res}, Port),
  {stop, normal, State};

handle_info(Info, #state{mod=Mod, client_state=Cstate}=State) ->
  case catch Mod:handle_info(Info, Cstate) of
    stop ->
      {stop, normal, State};
    {ok, NewCstate} ->
      {noreply, State#state{client_state = NewCstate}};
    {'EXIT', Reason} ->
      Mod:handle_log("error:~p", [Reason]),
      {noreply, State};
    _ ->
      {noreply, State}
  end.

code_change(_Oldvsn, State, _Extra) ->
  {ok, State}.

terminate(_Reason, _State) ->
  ok.


