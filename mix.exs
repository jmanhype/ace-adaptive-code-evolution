defmodule Ace.MixProject do
  use Mix.Project

  def project do
    [
      app: :ace,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      
      # Escript configuration
      escript: escript(),
      
      # Package and documentation
      name: "ACE",
      description: "Adaptive Code Evolution - AI-powered code optimization system",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/yourusername/ace",
      
      # Test coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      
      # Dialyzer configuration
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Ace.Application, []}
    ]
  end
  
  # Escript configuration for CLI
  defp escript do
    [
      main_module: Ace.CLI,
      name: "ace",
      app: nil,
      comment: "ACE - Adaptive Code Evolution"
    ]
  end
  
  # Package information for hex.pm
  defp package do
    [
      name: "ace",
      files: ~w(lib config .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/ace"}
    ]
  end
  
  # Documentation configuration
  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: [
        "Core": [
          Ace,
          Ace.Core.Analysis,
          Ace.Core.Opportunity,
          Ace.Core.Optimization,
          Ace.Core.Evaluation,
          Ace.Core.Experiment
        ],
        "Services": [
          Ace.Analysis.Service,
          Ace.Optimization.Service,
          Ace.Evaluation.Service
        ],
        "Infrastructure": [
          Ace.Infrastructure.AI.Provider,
          Ace.Infrastructure.AI.Orchestrator
        ],
        "AI Providers": [
          Ace.Infrastructure.AI.Providers.Groq
        ],
        "CLI": [
          Ace.CLI
        ],
        "Telemetry": [
          Ace.Telemetry,
          Ace.Telemetry.FunctionTracer
        ]
      ]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4.2"},
      {:ecto_sql, "~> 3.10.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_relay, "~> 1.5"},
      {:httpoison, "~> 2.0"},
      {:timex, "~> 3.7.11"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.real_world": ["run test/real_world/run_tests.exs"]
    ]
  end
end
