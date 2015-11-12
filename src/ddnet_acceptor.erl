%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 十月 2015 21:42
%%%-------------------------------------------------------------------
-module(ddnet_acceptor).
-author("wanghaohao").

-behaviour(gen_server).
%% API
-export([start_link/3]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
        terminate/2, code_change/3]).

-record(state, {mod, acceptor_port, lsock, ref}).

start_link(Mod, Port, Lsock) ->
  gen_server:start_link(?MODULE, [Mod, Port, Lsock], []).

init([Mod, Port, Lsock]) ->
  process_flag(trap_exit, true),
  self() ! {event, start},
  {ok, #state{mod=Mod, acceptor_port=Port, lsock=Lsock}}.

handle_call(_Req, _From, S) ->
  {reply, ok, S}.

handle_cast(_Msg, S) ->
  {noreply, S}.

handle_info({event, start}, S) ->
  accept(S);

handle_info({'EXIT', _, shutdown}, S) ->
  {stop, normal, S};

handle_info({inet_async, Lsock, Ref, {ok, Sock}}, S = #state{mod=Mod, acceptor_port=Port, lsock=Lsock, ref=Ref}) ->
  %% patch up the socket so it looks like one we got from
  %% gen_tcp:accept/1
  {ok, NetMod} = inet_db:lookup_socket(Lsock),
  inet_db:register_socket(Sock, NetMod),
  try
    %% report
    {ok, {Address, Port}} = inet:sockname(Lsock),
    {ok, {PeerAddress, PeerPort}} = inet:peername(Sock),
    Mod:handle_log("accept client serverAddr:~p, peeraddr:~p, peerport:~p", [Address, PeerAddress, PeerPort]),
    spawn_socket_controller(Port, Sock),
    accept(S)
  catch Error:Reason ->
    Mod:handle_log("accept error, tag:~p, reason:~p", [Error, Reason]),
    gen_tcp:close(Sock)
  end;


handle_info({inet_async, Lsock, Ref, {error, closed}}, State=#state{lsock=Lsock, ref=Ref}) ->
  %% It would be wrong to attempt to restart the acceptor when we
  %% know this will fail.
  {stop, normal, State};

handle_info(Info, #state{mod=Mod}=S) ->
  Mod:handle_log("acceptor recv unhandle msg:~p", [Info]),
  {noreply, S}.

terminate(_Reason, _S) ->
  ok.

code_change(_Oldvsn, S, _Extra) ->
  {ok, S}.

accept(S = #state{lsock=Lsock}) ->
  case prim_inet:async_accept(Lsock, -1) of
    {ok, Ref} ->
      {noreply, S#state{ref=Ref}};
    Error ->
      {stop, {cannot_accept, Error}, S}
  end.

spawn_socket_controller(Port, Sock) ->
  case supervisor:start_child(ddnet_client_sup, [Port, Sock]) of
    {ok, CPid} ->
      inet:setopts(Sock, [{packet, 4}, binary, {active, false}, {nodelay, true}, {delay_send, true}]),
      gen_tcp:controlling_process(Sock, CPid),
      gen_server:cast(CPid, start);
    {error, _Error} ->
      catch erlang:port_close(Sock)
  end.






