defmodule UeberauthHubspot.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_hubspot,
      name: "Üeberauth Hubspot",
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :oauth2, :ueberauth]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, path: "../crm/deps/ueberauth"}
      # {:ueberauth, "~> 0.10.0"}
    ]
  end
end
