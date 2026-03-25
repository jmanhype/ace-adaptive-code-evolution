# ACE: Adaptive Code Evolution

Elixir application that uses LLMs to analyze code, identify optimization opportunities, generate improved implementations, and apply them. Includes a Phoenix web dashboard.

## What It Does

1. Analyzes source files to find optimization opportunities (performance, maintainability, security, reliability)
2. Sends code to an LLM (Groq, OpenAI, or Anthropic) to generate optimized versions
3. Evaluates optimizations via compilation, tests, and benchmarks
4. Applies successful optimizations to the codebase

## Stack

| Component | Technology |
|-----------|-----------|
| Language | Elixir 1.14+ |
| Web | Phoenix 1.7, LiveView 0.20, LiveDashboard |
| Database | PostgreSQL (Ecto) |
| LLM providers | Groq (default), OpenAI, Anthropic -- via Finch HTTP |
| GraphQL | Absinthe |
| Frontend | esbuild, Tailwind |
| CLI | escript |

## Supported Languages

| Language | Support Level |
|----------|-------------|
| Elixir | Primary |
| JavaScript | Partial |
| Python | Partial |
| Ruby | Partial |
| Go | Partial |

## Project Structure

```
lib/
  ace/
    core/         # Analysis, Opportunity, Optimization, Evaluation, Experiment
    analysis/     # Analysis service
    optimization/ # Optimization service
    evaluation/   # Evaluation service
    infrastructure/ai/  # LLM provider abstraction (Groq, etc.)
    telemetry.ex  # Function tracing
    cli.ex        # Escript CLI entry point
assets/           # JS (esbuild), node_modules
config/           # Environment configs
```

## Setup

```bash
git clone https://github.com/jmanhype/ace-adaptive-code-evolution.git
cd ace-adaptive-code-evolution
mix deps.get
mix ecto.setup

# Set at least one LLM API key:
export GROQ_API_KEY=your_key
# Or: OPENAI_API_KEY, ANTHROPIC_API_KEY
```

## CLI Usage

```bash
mix escript.build  # Builds the 'ace' CLI

ace init                              # Initialize config
ace analyze lib/my_module.ex          # Analyze a file
ace analyze-project --dir ./project   # Analyze a directory
ace optimize <opportunity-id>         # Generate optimization
ace evaluate <optimization-id>        # Evaluate result
ace apply <optimization-id>           # Apply to codebase
```

## Web Dashboard

```bash
mix phx.server
# Visit http://localhost:4000
```

## Configuration

```bash
export ACE_LLM_PROVIDER=groq          # groq | openai | anthropic | mock
export ACE_LLM_MODEL=llama3-70b-8192  # Provider-specific model name
```

Without API keys, falls back to mock responses for testing.

## Status

The application structure is complete with Phoenix web dashboard, CLI, and LLM integration. The `mix.exs` references `yourusername/ace` in package links (not updated to actual repo). The `.env` file is committed to the repo. `node_modules` is checked into git. Docker support exists but docker-compose references need API key configuration. No published evaluation metrics for optimization quality.

## License

Not specified.
