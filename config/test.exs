import Config

config :ueberauth, Ueberauth,
  json_library: Jason,
  providers: [
    hubspot: {Ueberauth.Strategy.Hubspot, []}
  ]

config :ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
  client_id: "test-client-id",
  client_secret: "test-client-secret"

config :plug, :validate_header_keys_during_test, true
