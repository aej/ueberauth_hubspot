# Ueberauth Hubspot

> An Ueberauth Strategy for Hubspot

## Installation

Add `:ueberauth` and `:ueberauth_hubspot` to your `mix.exs`:

```elixir
defp deps do
  [
    # ...
    {:ueberauth, "~> 0.7"},
    {:ueberauth_cognito, "~> 0.1"}
  ]
end
```

Configure Ueberauth to use this strategy:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    hubspot: {Ueberauth.Strategy.Hubspot, []}
  ]
```

and configure the required values:

```elixir
config :ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
    client_id: hubspot_client_id,
    client_secret: hubspot_client_secret
```

Add the routes to the router:

```elixir
scope "/auth", MyWeb do
  get "/:provider", AuthController, :request
  get "/:provider/callback", AuthController, :callback
end
```

and create the corresponding controller:

```elixir
defmodule MyWeb.AuthController do
  use MyWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    # handle failture
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    # handle success
    # auth is a `%Ueberauth.Auth{}` struct, with Hubspot token and connected account info
    send_resp(conn, 200, "Succcess")
  end
end
```

## Copyright and License

Copyright (c) 2023 Andy Jones

Source code licensed under [MIT License](./LICENSE.md).