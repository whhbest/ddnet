%%%-------------------------------------------------------------------
%%% @author wanghaohao
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十一月 2015 15:00
%%%-------------------------------------------------------------------
-module(ddnet_callback).
-author("wanghaohao").

-type socket() :: port().

-callback init(Sock :: socket()) -> {ok, any()}.
-callback handle_data(Data :: any(), any()) -> stop | {ok, any()} | any().
-callback handle_closed({recv_error | send_error, any()}, Port :: integer()) -> any().
-callback handle_info(any(), any()) -> stop | {ok, any()} | any().
-callback handle_log(Format::any(), any()) -> any().


