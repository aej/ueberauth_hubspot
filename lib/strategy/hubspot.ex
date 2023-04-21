defmodule Ueberauth.Strategy.Hubspot do
  use Ueberauth.Strategy

  def handle_request!(conn) do
    scope = conn.params["scope"] || option(conn, :default_scope)

    opts = [scopes: scope, redirect_uri: callback_url(conn)] |> with_state_param(conn)

    redirect!(conn, Ueberauth.Strategy.Hubspot.OAuth.authorize_url!(opts))
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    redirect_uri = callback_url(conn)

    %OAuth2.AccessToken{} =
      access_token =
      [code: code, redirect_uri: redirect_uri]
      |> Ueberauth.Strategy.Hubspot.OAuth.get_token!(redirect_uri: redirect_uri)

    if access_token.access_token == nil do
      err = access_token.other_params["error"]
      desc = access_token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      put_private(conn, :hubspot_token, access_token)
      |> fetch_access_token_info(access_token)
    end
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def handle_cleanup!(conn) do
    put_private(conn, :hubspot_token, nil)
  end

  def credentials(conn) do
    token = conn.private.hubspot_token

    %Ueberauth.Auth.Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: conn.private.access_token_info["scopes"],
      refresh_token: token.refresh_token,
      token: token.access_token,
      token_type: token.token_type
    }
  end

  def extra(conn) do
    access_token_info = conn.private.access_token_info

    %Ueberauth.Auth.Extra{
      raw_info: %{
        hub_id: access_token_info["hub_id"],
        app_id: access_token_info["app_id"]
      }
    }
  end

  def info(conn) do
    %Ueberauth.Auth.Info{
      email: conn.private.access_token_info["user"]
    }
  end

  # Private

  defp fetch_access_token_info(conn, %OAuth2.AccessToken{} = access_token) do
    # We need to hit another endpoint to get the user's email address.
    # We just stick this response in the conn and fetch it out in the strategy callbacks
    base_api_url = Ueberauth.Strategy.Hubspot.OAuth.base_api_url()
    url = "#{base_api_url}/oauth/v1/access-tokens/#{access_token.access_token}"
    resp = Ueberauth.Strategy.Hubspot.OAuth.get(url)

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
      when status_code in 200..399 ->
        put_private(conn, :access_token_info, body)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
