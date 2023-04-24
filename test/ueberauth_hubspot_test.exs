defmodule UeberauthHubspotTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Plug.Conn

  import Ueberauth.Strategy.Helpers

  doctest UeberauthHubspot

  defmodule SpecRouter do
    use Plug.Router

    @session_options [
      store: :cookie,
      key: "_my_key",
      signing_salt: "CXlmrshG"
    ]

    plug Plug.Session, @session_options

    plug :fetch_query_params

    plug Ueberauth

    plug :match
    plug :dispatch

    get "/auth/hubspot", do: send_resp(conn, 200, "auth0 request")
    get "/auth/hubspot/callback", do: send_resp(conn, 200, "auth0 callback")
  end

  @session_options Plug.Session.init(
                     store: Plug.Session.COOKIE,
                     key: "_my_key",
                     signing_salt: "CXlmrshG"
                   )
  @router SpecRouter.init([])

  test "handle_request!/1 redirects to the hubspot auth url" do
    conn =
      :get
      |> conn("/auth/hubspot", %{})
      |> SpecRouter.call(@router)

    assert conn.status == 302
    assert [location] = get_resp_header(conn, "location")

    assert location =~ "https://app.hubspot.com/oauth/authorize"
    assert location =~ "client_id=test-client-id"
    assert location =~ "scopes=oauth"
    assert location =~ "state=#{conn.private[:ueberauth_state_param]}"
  end

  test "handle_callback!/1 fetches the token" do
    TestServer.add("/oauth/v1/token",
      via: :post,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            access_token: "the-access-token",
            refresh_token: "the-refresh-token",
            expires_in: 3600
          })
        )
      end
    )

    TestServer.add("/oauth/v1/access-tokens/the-access-token",
      via: :get,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "scopes" => ["oauth"],
            "hub_id" => 123,
            "app_id" => 456
          })
        )
      end
    )

    Application.put_env(:ueberauth_hubspot, :base_api_url, TestServer.url())

    conn =
      :get
      |> conn("/auth/hubspot/callback?state=123&code=abc")
      |> init_test_session(%{})
      |> Plug.Conn.fetch_query_params()
      |> Ueberauth.Strategy.Hubspot.handle_callback!()
  end
end
