%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 20:28
%%%-------------------------------------------------------------------
-module(ddnet_listener).
-author("wanghaohao").

-behaviour(gen_server).

%% API
-export([start_link/4]).

%% gen_server callback
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
        terminate/2, code_change/3]).

-define(TCP_OPTS, [
  binary,
  {packet, 0},
  {reuseaddr, true},
  {nodelay, true},
  {delay_send, true},
%%   {active, false},
  {backlog, 1024},
  {exit_on_close, false},
  {send_timeout, 15000}
]).

-include_lib("kernel/include/inet.hrl").

-record(state, {mod, port, sock, onstart, onstop, ref}).

start_link(Mod, Port, OnlistenSucc, OnlistenErr) ->
  gen_server:start_link(?MODULE, [Mod, Port, OnlistenSucc, OnlistenErr], []).

init([Mod, Port, OnlistenSucc, OnlistenErr]) ->
  process_flag(trap_exit, true),
  %% todo 多ip的情况
  case gen_tcp:listen(Port, ?TCP_OPTS ++ [{active, false}]) of
    {ok, Sock} ->
      {ok, {IPAddress, Port}} = inet:sockname(Sock),
      OnlistenSucc(IPAddress, Port, Sock),
      Ref = make_ref(),
      self() ! {start_acceptor, Ref},

      {ok, #state{mod=Mod, port=Port, sock=Sock,
                  onstart=OnlistenSucc,
                  onstop=OnlistenErr,
                  ref=Ref}};
    {error, Reason} ->
      OnlistenErr(Port, Reason),
      {stop, {listen_error, Port, Reason}}
  end.

handle_call(_Req, _From, S) ->
  {reply, ok, S}.

handle_cast(_Msg, S) ->
  {noreply, S}.

handle_info({start_acceptor, Ref}, #state{mod=Mod, sock=Sock, ref=Ref, port=Port}=S) ->
  ddnet_acceptor_sup:start_acceptors(Mod, Port, Sock),
  {noreply, S};
handle_info({start_acceptor, Info}, #state{mod=Mod}=S) ->
  Mod:handle_log("system attacked by start_accpetor, passinfo:~w", [Info]),
  {noreply, S};

handle_info(_Info, S) ->
  {noreply, S}.

terminate(Reason, #state{port=Port, sock=Lsock, onstop=Onstop}) ->
  {ok, {IPAddress, Port}} = inet:sockname(Lsock),
  gen_tcp:close(Lsock),

  Onstop({Port, IPAddress}, Reason),
  ok.

code_change(_Oldvsn, S, _Extra) ->
  {ok, S}.


