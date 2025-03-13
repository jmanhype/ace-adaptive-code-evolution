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
      # HTTP client
      {:httpoison, "~> 2.1"},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      
      # Code parsing and manipulation
      {:sourceror, "~> 1.0"},
      
      # GraphQL (added)
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_relay, "~> 1.5"},
      
      # Phoenix (added)
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.4"},
      
      # AI/LLM integration
      # We'll implement without relying on instructor_ex since it's not available in the registry
      
      # Telemetry and monitoring
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      
      # Web API
      {:plug_cowboy, "~> 2.6"},
      
      # Testing
      {:mox, "~> 1.0", only: :test},
      {:stream_data, "~> 0.5", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test},
      
      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      
      # Development tools
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
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
