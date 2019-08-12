defmodule RubberBand.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :rubberband,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]],

      # Docs
      name: "App Monitoring",
      source_url:
        "https://github.com/tlux/rubberband/blob/master/%{path}#L%{line}",
      homepage_url: "https://github.com/tlux/rubberband",
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
      {:mox, "~> 0.5", only: :test},
      {:plug, "~> 1.7"}
    ]
  end
end
