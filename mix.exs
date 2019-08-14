defmodule RubberBand.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :rubber_band,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      preferred_cli_env: [
        ci: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        dialyzer: :test
      ],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]],

      # Docs
      name: "App Monitoring",
      source_url:
        "https://github.com/tlux/rubber_band/blob/master/%{path}#L%{line}",
      homepage_url: "https://github.com/tlux/rubber_band",
      docs: [
        main: "readme",
        extras: ["README.md"],
        groups_for_modules: []
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:jason, "~> 1.1", optional: true},
      {:httpoison, "~> 1.5"},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer",
        "test --cover"
      ]
    ]
  end
end
