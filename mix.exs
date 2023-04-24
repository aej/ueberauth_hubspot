defmodule UeberauthHubspot.MixProject do
  use Mix.Project

  @source_url "https://github.com/aej/ueberauth_hubspot"
  @version "0.1.0"

  def project do
    [
      app: :ueberauth_hubspot,
      name: "Üeberauth Hubspot",
      version: @version,
      source_url: @source_url,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "An Ueberauth strategy for integrating with Hubspot",
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :oauth2, :ueberauth]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: [
        "Andy Jones <andy@andyjones.co>"
      ],
      links: %{
        "Changelog" => "https://hexdocs.pm/ueberauth_hubspot/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "#{@version}",
      formatters: ["html"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, "~> 0.10.0"},
      {:jason, "~> 1.0"},

      # Test only
      {:test_server, "~> 0.1", only: [:test]},
      {:ex_doc, "~> 0.26.0", only: :dev, runtime: false}
    ]
  end
end
