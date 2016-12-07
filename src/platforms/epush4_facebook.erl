%%
%% Facebook push notification sending
%% https://developers.facebook.com/docs/games/services/appnotifications
%%

-module(epush4_facebook).

-include("../../include/epush4.hrl").

-export([push/3]).

-define(IBROWSE_OPTIONS(ContentType), [  % Ibrowse options ContentType = "text/html"
          {max_sessions, 1000},
          {max_pipeline_size, 500},
          {connect_timeout, 2000},
          {inactivity_timeout, 4000},
          {content_type, ContentType}]).


push(Key, #{<<"token">> := Token}, Payload) ->
  push(Key, Token, Payload);
push(Key, Token, Payload) ->
  Options  = ?IBROWSE_OPTIONS("text/html"),
  Headers  = [{"Content-Type", "application/x-www-form-urlencoded"}],
  PostData = lists:append(["access_token=", binary_to_list(Key),
                           "&href=index.html?gift_id=123",
                           "&template=", binary_to_list(Payload)]),
  send_message(PostData, Options, Headers, Token).



-define(FACEBOOK_BASEURL, "https://graph.facebook.com/").
-define(FACEBOOK_IBROWSE_SEND_TIMEOUT, 3000). %% msec


%
send_message(PostData, Options, Headers, Token) ->
  Url = lists:append([?FACEBOOK_BASEURL, binary_to_list(Token), "/notifications"]),
  case ibrowse:send_req(Url, Headers, post, PostData, Options, ?FACEBOOK_IBROWSE_SEND_TIMEOUT) of
    {ok, Status, _RHeaders, Body} -> parse_answer(Status, list_to_binary(Body));
    {error,req_timedout}          -> ?e(timeout);
    Else                          -> ?e(unknown_response_error, Else)
  end.


parse_answer(Status, Body) when Status == "200" -> 
  ?INF("parse_answer Body", Body),
  ok;
parse_answer(Status, Body) ->
  ?INF("parse_answer Status", Status),
  case jsx:is_json(Body) of
    true ->
      case jsx:decode(Body, [return_maps]) of
        #{<<"code">> := 100} -> ?e(too_long_text);
        #{<<"code">> := 200} -> ?e(not_registered);
        Else                 -> ?e(unknown_response_error, Else)
      end; 
    false -> ?e(unknown_response_error)
  end.
