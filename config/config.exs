import Config

config :ueberauth_hubspot,
  base_api_url: "https://api.hubapi.com"

if Mix.env() == :test, do: import_config("#{Mix.env()}.exs")
