# ACE: Adaptive Code Evolution

[![CI Status](https://github.com/yourusername/ace/workflows/ACE%20CI/badge.svg)](https://github.com/yourusername/ace/actions)
[![Coverage](https://codecov.io/gh/yourusername/ace/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/ace)
[![License](https://img.shields.io/github/license/yourusername/ace)](LICENSE)

ACE is an AI-powered code optimization system that automatically identifies optimization opportunities, generates improved implementations, evaluates their effectiveness, and applies successful optimizations to your codebase.

## Features

- **Code Analysis**: Analyze code to identify optimization opportunities
- **Opportunity Detection**: Find performance, maintainability, security, and reliability issues
- **AI-Powered Optimization**: Generate optimized implementations using LLM models (Groq, OpenAI, Anthropic)
- **Automated Evaluation**: Verify optimizations through compilation, testing, and benchmarking
- **Safe Application**: Apply optimizations to your codebase with confidence
- **GitHub Integration**: Automatically analyze and optimize pull requests with GitHub App integration
- **Multiple Languages**: Support for Elixir, JavaScript, Python, Ruby, and Go (with varying levels of support)
- **Multi-file Analysis**: Identify optimization opportunities across file boundaries with relationship visualization
- **Web Dashboard**: Visualize and manage optimization opportunities through a web interface
- **Extensible Architecture**: Create custom analyzers and optimization strategies

## Installation

### API Keys

ACE uses large language models to analyze and optimize code. You'll need at least one of these API keys:

- **Groq API**: Set `GROQ_API_KEY` environment variable (recommended)
- **OpenAI API**: Set `OPENAI_API_KEY` environment variable 
- **Anthropic API**: Set `ANTHROPIC_API_KEY` environment variable

If no API keys are provided, ACE will fall back to using mock responses for testing purposes.

### Pre-built Binaries

Download the latest release for your platform:

```bash
# Linux
curl -LO https://github.com/yourusername/ace/releases/latest/download/ace-linux
chmod +x ace-linux
sudo mv ace-linux /usr/local/bin/ace

# macOS
curl -LO https://github.com/yourusername/ace/releases/latest/download/ace-macos
chmod +x ace-macos
sudo mv ace-macos /usr/local/bin/ace
```

### Docker

```bash
# Pull the image
docker pull ghcr.io/yourusername/ace:latest

# Run the CLI
docker run -e GROQ_API_KEY=$GROQ_API_KEY ghcr.io/yourusername/ace:latest analyze --file path/to/file.ex

# Run with Docker Compose (for web dashboard)
git clone https://github.com/yourusername/ace.git
cd ace/ace_standalone

# Edit docker-compose.yml to uncomment and set API keys
# Or export environment variables to pass through:
export GROQ_API_KEY=your_api_key_here

docker-compose up -d
# Access the dashboard at http://localhost:4000
```

### From Source

```bash
# Install from source
git clone https://github.com/yourusername/ace.git
cd ace/ace_standalone
mix deps.get
mix escript.build
# This creates an executable named 'ace'

# Add to your PATH
sudo cp ace /usr/local/bin/
```

### Production Deployment

For production deployments, we recommend using Docker:

1. Set up your environment variables:
   ```bash
   export GROQ_API_KEY=your_api_key
   export ACE_LLM_PROVIDER=groq  # Options: groq, openai, anthropic, mock
   export ACE_LLM_MODEL=llama3-70b-8192  # See provider docs for models
   ```

2. Edit docker-compose.yml to uncomment the environment variables section

3. Run with proper database configuration:
   ```bash
   # Start the database and let it initialize
   docker-compose up -d db
   sleep 10
   
   # Start the application
   docker-compose up -d app
   ```

4. For production PostgreSQL settings, modify the docker-compose.yml:
   ```yaml
   db:
     environment:
       - POSTGRES_USER=secure_username
       - POSTGRES_PASSWORD=strong_password
       - POSTGRES_DB=ace_prod
   ```

### As a Library

Add `ace` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ace, "~> 0.1.0"}
  ]
end
```

## Usage

### Command Line

```bash
# Initialize configuration
ace init

# Analyze a file
ace analyze lib/my_module.ex

# Analyze multiple files as a project
ace analyze-project --dir ./project_directory

# Optimize an opportunity
ace optimize 12345-abcde-67890

# Evaluate an optimization
ace evaluate 67890-fghij-12345

# Apply an optimization
ace apply 54321-klmno-09876

# Run the complete pipeline on a single file
ace run lib/my_module.ex --strategy performance --focus-areas performance,maintainability

# Start the web dashboard
ace serve
```

### Web Dashboard

After starting the web server with `ace serve` or Docker Compose, navigate to:

```
http://localhost:4000
```

The dashboard provides:
- File browsing and analysis
- Visualization of optimization opportunities
- Opportunity details and suggested changes
- Interactive optimization and evaluation
- Multi-file project management
- Performance metrics and charts

### As a Library

```elixir
# Analyze a file
{:ok, analysis} = Ace.analyze_file("lib/my_module.ex")

# List opportunities
{:ok, opportunities} = Ace.list_opportunities(analysis_id: analysis.id)

# Generate an optimization
{:ok, optimization} = Ace.optimize(opportunity.id, "performance")

# Evaluate the optimization
{:ok, evaluation} = Ace.evaluate_optimization(optimization.id)

# Apply a successful optimization
if evaluation.success do
  {:ok, applied} = Ace.apply_optimization(optimization.id)
end

# Or use the complete pipeline
{:ok, results} = Ace.run_pipeline("lib/my_module.ex", 
  strategy: "performance", 
  focus_areas: ["performance", "maintainability"],
  auto_apply: false
)
```

## GitHub App Integration

### Automatic Pull Request Optimization

ACE can automatically analyze and optimize your pull requests, similar to how CodeFlash works:

1. **Install the GitHub App**
   
   Install the ACE GitHub App on your repositories to grant necessary permissions:
   - Read/write access to code and pull requests
   - Read access to repository metadata
   - Receive webhook events for pull requests

2. **Automatic PR Analysis**
   
   When a new pull request is opened or updated:
   - ACE automatically detects the changes
   - Analyzes the modified code for optimization opportunities
   - Generates optimization suggestions
   - Posts detailed comments with improvement recommendations

3. **Optimization Application**
   
   For identified optimizations, ACE can:
   - Create optimization suggestions as comments
   - Generate a follow-up PR with applied optimizations
   - Provide before/after performance metrics when available

4. **Setup GitHub Actions Workflow**

   Add the ACE workflow to your repository:

   ```yaml
   # .github/workflows/ace-optimize.yml
   name: ACE Code Optimization

   on:
     pull_request:
       types: [opened, reopened, synchronize]

   jobs:
     optimize:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout code
           uses: actions/checkout@v3
           with:
             fetch-depth: 0

         - name: Run ACE Optimization
           uses: ace-ai/optimize-action@v1
           with:
             api-key: ${{ secrets.ACE_API_KEY }}
             focus-areas: performance,maintainability
           # Optional configuration
           # strategy: comprehensive
           # max-suggestions: 5
   ```

5. **Configuration Options**

   Configure optimization behavior in your project root:

   ```json
   // ace.config.json
   {
     "github": {
       "auto_optimize_prs": true,
       "focus_areas": ["performance", "maintainability"],
       "max_suggestions_per_pr": 10,
       "ignore_paths": ["vendor/**", "node_modules/**"],
       "strategy": "balanced"
     }
   }
   ```

### Benefits

- **Continuous Code Quality**: Every PR gets automatically analyzed for potential optimizations
- **Zero Developer Effort**: No manual triggers needed after initial setup
- **Actionable Feedback**: Specific, contextual optimization suggestions
- **Educational Value**: Developers learn optimization patterns from AI suggestions

## Custom Analyzers and Strategies

ACE can be extended with custom analyzers and optimization strategies:

```elixir
# Define a custom analyzer
Ace.define_analyzer :memory_efficiency,
  focus_areas: ["performance"],
  severity_threshold: "medium",
  fn code, language ->
    # Custom analysis logic to identify memory inefficiencies
    # Returns a list of optimization opportunities
  end

# Define a custom optimization strategy
Ace.define_strategy :functional_refactoring,
  priority: ["maintainability", "reliability"],
  fn opportunity, original_code ->
    # Custom optimization logic to refactor to a more functional style
    # Returns optimized code
  end
```

## Configuration

ACE can be configured through a `.ace.yaml` file or through environment variables:

```yaml
# AI provider configuration
ai_provider: "groq"
ai_model: "llama3-70b-8192"

# Default analysis settings
default_focus_areas: ["performance", "maintainability"]
default_severity_threshold: "medium"

# Default optimization settings
default_strategy: "auto"

# Output settings
default_format: "text"
```

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+

### Setup

```bash
git clone https://github.com/yourusername/ace.git
cd ace/ace_standalone
mix deps.get
mix setup
```

### Testing

```bash
mix test                  # Run tests
mix test --cover          # Run with coverage
mix credo --strict        # Static code analysis
mix dialyzer              # Type checking
```

### Building Releases

```bash
# Build CLI executable
MIX_ENV=prod mix escript.build

# Create a release tag
git tag v0.1.0
git push origin v0.1.0  # Triggers release workflow
```

### CI/CD

This project uses GitHub Actions for continuous integration and deployment:

- **CI Workflow**: Runs tests, static analysis, and type checking on every push and PR
- **Coverage Workflow**: Generates and uploads test coverage reports
- **Release Workflow**: Builds and publishes binaries for multiple platforms on tag push
- **Docker Workflow**: Builds and publishes Docker images

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

- [USAGE.md](USAGE.md) - Detailed usage guide for ACE
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overview of ACE's architecture
- [docs/multi_file_analysis.md](docs/multi_file_analysis.md) - Guide to multi-file analysis and relationship visualization
- [docs/liveview.md](docs/liveview.md) - Documentation for the LiveView dashboard interface
- [docs/real_world_testing.md](docs/real_world_testing.md) - Guide to testing ACE with real-world codebases