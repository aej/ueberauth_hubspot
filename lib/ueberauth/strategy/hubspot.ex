defmodule Ueberauth.Strategy.Hubspot do
  use Ueberauth.Strategy, default_scope: "oauth"

  def handle_request!(conn) do
    scopes = conn.params["scope"] || Keyword.get(default_options(), :default_scope)

    opts = [scopes: scopes, redirect_uri: callback_url(conn)] |> with_state_param(conn)

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
      conn
      |> put_private(:token, access_token)
      |> fetch_user(access_token)
    end
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def handle_cleanup!(conn) do
    put_private(conn, :token, nil)
  end

  def credentials(conn) do
    token = conn.private.token
    hubspot_token = conn.private.hubspot_token

    %Ueberauth.Auth.Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: hubspot_token["scopes"],
      refresh_token: token.refresh_token,
      token: token.access_token,
      token_type: token.token_type
    }
  end

  def extra(conn) do
    hubspot_token = conn.private.hubspot_token

    %Ueberauth.Auth.Extra{
      raw_info: %{
        hub_id: hubspot_token["hub_id"]
      }
    }
  end

  def info(conn) do
    hubspot_token = conn.private.hubspot_token

    %Ueberauth.Auth.Info{
      email: hubspot_token["user"]
    }
  end

  # Private

  defp fetch_user(conn, %OAuth2.AccessToken{} = access_token) do
    url = "https://api.hubapi.com/oauth/v1/access-tokens/#{access_token.access_token}"
    resp = Ueberauth.Strategy.Hubspot.OAuth.get(url)

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
      when status_code in 200..399 ->
        put_private(conn, :hubspot_token, body)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end
end
