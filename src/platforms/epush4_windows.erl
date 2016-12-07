%%
%% Windows push sending
%%

%% DOCS
%%
%%

-module(epush4_windows).

-include("../../include/epush4.hrl").

-export([push/3]).



%% 
-define(IBROWSE_OPTIONS(ContentType), [  % Ibrowse options ContentType = "text/html"
          {max_sessions, 1000},
          {max_pipeline_size, 500},
          {connect_timeout, 2000},
          {inactivity_timeout, 4000},
          {ssl_options, [{versions, ['tlsv1.2']}]},
          {content_type, ContentType}]).
-define(SEND_TIMEOUT, 5000).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% push
push(Key, #{<<"token">> := Token}, Payload) -> push(Key, Token, Payload);
push(Key, Token, Payload) ->
  Options = ?IBROWSE_OPTIONS("application/json"),
  Headers = [
    {"Authorization", Key},
    {"Content-Type",  "text/xml"},
    {"X-WNS-Type",    "wns/toast"}, % X-WNS-Type: wns/toast | wns/badge | wns/tile | wns/raw
    {"X-WNS-RequestForStatus", "true"}],
  
  try
    case ibrowse:send_req(binary_to_list(Token), Headers, post, Payload, Options, 3000) of
      {ok, "200", _RetHeaders, _BodyData} -> ok;
      {ok, "401", _RetHeaders, _BodyData} -> ?e(wrong_key);
      {ok, "403", _RetHeaders, _BodyData} -> ?e(wrong_app_key);
      {ok, "410", _RetHeaders, _BodyData} -> ?e(not_registered);
      {ok, Status, RetHeaders,  BodyData} ->
          ?INF("Windows push error", {?p, {Status, RetHeaders, BodyData}}),
          ?e(unknown_response_error);
      Else ->
        ?INF("Windows push error", {?p, Else}),
        ?e(unknown_response_error)
    end
  catch
    E:R ->
      ?INF("Windows crash request", {E,R, Token, Payload}),
      ?e(unknown_response_error)
  end.
