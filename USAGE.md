# ACE: Adaptive Code Evolution - Usage Guide

This guide provides examples of how to use ACE in various scenarios.

## Quick Start

### Configuration

#### API Keys

ACE requires at least one of the following API keys:

```bash
# Recommended: Groq API (llama3-70b-8192 model)
export GROQ_API_KEY=your_api_key

# Alternative: OpenAI API (requires gpt-4 or better)
export OPENAI_API_KEY=your_api_key

# Alternative: Anthropic API (requires Claude models)
export ANTHROPIC_API_KEY=your_api_key
```

**Note**: If no API keys are provided, ACE will use mock responses for testing purposes.

### Installation

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/ace.git
cd ace/ace_standalone

# Install dependencies
mix deps.get

# Build the CLI executable
mix escript.build

# The executable will be named 'ace' in the current directory
# Optionally add to your PATH
sudo cp ace /usr/local/bin/
```

#### Using Docker

```bash
# Build and run using Docker
docker build -t ace-cli .
docker run -v $(pwd):/code ace-cli analyze /code/your_file.ex
```

### Quick Examples

```bash
# Analyze a file for optimization opportunities
./ace analyze path/to/your_file.ex

# Run the complete pipeline (analyze, optimize, evaluate)
./ace run path/to/your_file.ex

# Run with auto-apply to automatically apply successful optimizations
./ace run path/to/your_file.ex --auto-apply
```

## Command Line Usage

### Basic Analysis

Analyze a single file to identify optimization opportunities:

```bash
# Analyze a file with default settings
ace analyze lib/my_module.ex

# Analyze with specific focus areas
ace analyze lib/my_module.ex --focus-areas performance,security

# Analyze with custom severity threshold
ace analyze lib/my_module.ex --severity-threshold high

# Output in JSON format
ace analyze lib/my_module.ex --format json

# Write results to a file
ace analyze lib/my_module.ex --output results.json
```

### Generating Optimizations

Generate optimized implementations for identified opportunities:

```bash
# Optimize a specific opportunity (use IDs from analyze output)
ace optimize abc123-def456-789

# Use a specific optimization strategy
ace optimize abc123-def456-789 --strategy performance

# Optimize multiple opportunities at once
ace optimize abc123-def456-789 def456-ghi789-012
```

### Evaluating Optimizations

Evaluate the effectiveness of optimizations:

```bash
# Evaluate an optimization
ace evaluate xyz987-uvw654-321

# Evaluate multiple optimizations
ace evaluate xyz987-uvw654-321 tuv543-qrs210-987
```

### Applying Optimizations

Apply successful optimizations to your codebase:

```bash
# Apply an optimization
ace apply lmn432-opq098-765

# Apply multiple optimizations
ace apply lmn432-opq098-765 hij321-klm654-987
```

### Complete Pipeline

Run the entire ACE pipeline in one command:

```bash
# Run the full pipeline without automatically applying optimizations
ace run lib/my_module.ex

# Run the pipeline with auto-apply
ace run lib/my_module.ex --auto-apply

# Run with custom settings
ace run lib/my_module.ex --strategy maintainability --focus-areas maintainability,reliability
```

## Real-World Examples

### Optimizing Inefficient Data Processing

```bash
# Analyze a file with inefficient data processing
ace analyze lib/data_processor.ex

# Sample output:
# Opportunity 123abc-def456: Inefficient list processing at line 25
# Replace `Enum.reduce(list, [], fn x, acc -> acc ++ [process(x)] end)`
# with `Enum.map(list, &process/1)` for better performance

# Apply optimization directly
ace run lib/data_processor.ex --auto-apply
```

### Finding Security Issues

```bash
# Analyze code for security vulnerabilities
ace analyze lib/user_controller.ex --focus-areas security

# Sample output:
# Opportunity 789xyz-123abc: Potential SQL injection at line 42
# Parameters should be properly escaped using parameterized queries
```

### Multi-File Analysis

```bash
# Analyze multiple files in a project
ace analyze-project --dir ./lib

# This identifies cross-file optimization opportunities
```

## Web Dashboard

ACE includes a web dashboard for a more visual approach to code optimization:

```bash
# Start the web server
mix phx.server

# Access the dashboard at http://localhost:4000
```

The dashboard provides:
- File browsing and analysis
- Visualization of optimization opportunities
- Opportunity details and suggested changes
- Interactive optimization and evaluation
- Multi-file project management
- Performance metrics and charts

## Configuration

### Configuration File

Create a `.ace.yaml` file for project-wide configuration:

```yaml
# AI provider configuration
ai_provider: "groq"
ai_model: "llama3-70b-8192"
api_key_env: "GROQ_API_KEY"

# Default analysis settings
default_focus_areas: 
  - performance
  - maintainability
  - security
default_severity_threshold: "medium"

# Default optimization settings
default_strategy: "auto"
auto_apply: false

# Output settings
default_format: "text"

# Ignore patterns
ignore_patterns:
  - "test/**/*_test.exs"
  - "priv/static/**/*"
  - "deps/**/*"
```

### Environment Variables

Configure ACE with environment variables:

```bash
# AI provider configuration
export ACE_AI_PROVIDER=groq
export ACE_AI_MODEL=llama3-70b-8192
export GROQ_API_KEY=your-api-key

# Default settings
export ACE_DEFAULT_FOCUS_AREAS=performance,maintainability
export ACE_DEFAULT_SEVERITY_THRESHOLD=medium

# Run ACE with env var configuration
ace analyze lib/my_module.ex
```

## Library Integration

### Basic Setup

Add ACE to your dependencies:

```elixir
defp deps do
  [
    {:ace, "~> 0.1.0"}
  ]
end
```

### Using the API

```elixir
# Analyze a file
{:ok, analysis} = Ace.analyze_file("lib/my_module.ex")

# List optimization opportunities
{:ok, opportunities} = Ace.list_opportunities(analysis_id: analysis.id)

# Generate an optimization
opportunity_id = List.first(opportunities).id
{:ok, optimization} = Ace.optimize(opportunity_id)

# Evaluate the optimization
{:ok, evaluation} = Ace.evaluate_optimization(optimization.id)

# Apply if successful
if evaluation.success do
  {:ok, _} = Ace.apply_optimization(optimization.id)
end

# Or run the complete pipeline
{:ok, results} = Ace.run_pipeline("lib/my_module.ex")
```

### Usage in a Mix Task

Create a custom mix task for your project:

```elixir
defmodule Mix.Tasks.Optimize do
  use Mix.Task

  @shortdoc "Optimizes code using ACE"
  def run(args) do
    # Parse arguments
    {opts, files, _} = OptionParser.parse(args, 
      strict: [auto_apply: :boolean],
      aliases: [a: :auto_apply]
    )
    
    # Start the application
    Mix.Task.run("app.start")
    
    # Process each file
    Enum.each(files, fn file ->
      Mix.shell().info("Optimizing #{file}...")
      
      case Ace.run_pipeline(file, auto_apply: Keyword.get(opts, :auto_apply, false)) do
        {:ok, results} ->
          opp_count = length(results.opportunities)
          success_count = Enum.count(results.evaluations, & &1.success)
          applied_count = length(results.applied)
          
          Mix.shell().info("Found #{opp_count} opportunities.")
          Mix.shell().info("Successfully optimized #{success_count} issues.")
          Mix.shell().info("Applied #{applied_count} optimizations.")
          
        {:error, reason} ->
          Mix.shell().error("Failed: #{reason}")
      end
    end)
  end
end
```

## Custom Analyzers

Create custom analyzers for domain-specific optimizations:

### Simple Custom Analyzer

```elixir
Ace.define_analyzer :unused_variables,
  focus_areas: ["maintainability"],
  severity_threshold: "medium",
  fn code, language ->
    case language do
      "elixir" ->
        # Simple regex-based detection (a real implementation would use AST parsing)
        matches = Regex.scan(~r/_([a-zA-Z0-9_]+) =/, code)
        
        Enum.map(matches, fn [full_match, var_name] ->
          line_number = find_line_number(code, full_match)
          
          %{
            location: "line #{line_number}",
            type: "maintainability",
            description: "Unused variable #{var_name}",
            severity: "medium",
            rationale: "Unused variables make code harder to understand",
            suggested_change: "Remove the variable or use it"
          }
        end)
      
      _ ->
        []
    end
  end

# Helper function
defp find_line_number(code, pattern) do
  code
  |> String.split("\n")
  |> Enum.find_index(&String.contains?(&1, pattern))
  |> Kernel.+(1)
end
```

### Advanced Custom Analyzer with AST Parsing

```elixir
Ace.define_analyzer :long_functions,
  focus_areas: ["maintainability"],
  severity_threshold: "medium",
  fn code, language ->
    case language do
      "elixir" ->
        # Parse code into AST
        {:ok, ast} = Code.string_to_quoted(code)
        
        # Find function definitions
        functions = extract_functions(ast)
        
        # Identify long functions (more than 20 lines)
        Enum.filter_map(functions, 
          fn {_name, _arity, lines} -> lines > 20 end,
          fn {name, arity, lines} ->
            %{
              location: "function #{name}/#{arity}",
              type: "maintainability",
              description: "Long function with #{lines} lines",
              severity: lines > 50 && "high" || "medium",
              rationale: "Long functions are harder to understand and maintain",
              suggested_change: "Consider breaking this function into smaller, focused functions"
            }
          end
        )
      
      _ ->
        []
    end
  end

# Helper function to extract functions and their line counts
defp extract_functions(ast) do
  # Real implementation would traverse the AST
  # This is simplified for the example
  []
end
```

## Custom Strategies

Create custom optimization strategies:

### Performance Strategy

```elixir
Ace.define_strategy :tail_recursion_optimization,
  priority: ["performance"],
  fn opportunity, original_code ->
    if String.contains?(opportunity.type, "performance") &&
       String.contains?(opportunity.description, "recursion") do
      
      # Real implementation would parse and transform the code
      # This is simplified for the example
      optimized_code = convert_to_tail_recursive(original_code)
      
      # Return optimized code and explanation
      {optimized_code, "Converted to tail-recursive implementation for better performance"}
    else
      # Not applicable for this opportunity
      {original_code, "No tail recursion optimization possible"}
    end
  end

# Helper function
defp convert_to_tail_recursive(code) do
  # Real implementation would transform the code
  # This is simplified for the example
  code
end
```

### Functional Style Strategy

```elixir
Ace.define_strategy :functional_style,
  priority: ["maintainability", "reliability"],
  fn opportunity, original_code ->
    if String.contains?(opportunity.type, "maintainability") do
      # Convert imperative style to functional style
      # This is simplified for the example
      optimized_code = original_code
        |> replace_for_loops_with_map()
        |> replace_mutable_variables()
        |> add_function_composition()
      
      {optimized_code, "Refactored to more functional style for improved maintainability"}
    else
      {original_code, "No functional style optimizations applicable"}
    end
  end

# Helper functions would implement the actual transformations
```

## Multi-File Projects

ACE can analyze relationships between files in a project:

### Project-Wide Analysis

```bash
# Analyze all Elixir files in a project
ace analyze lib/**/*.ex

# Run the pipeline on multiple files
ace run lib/module1.ex lib/module2.ex lib/module3.ex
```

### Context-Aware Optimization

ACE provides powerful multi-file analysis capabilities that detect relationships between files and identify cross-file optimization opportunities.

For simple usage:

```bash
# Analyze multiple files as a project
ace analyze-project --dir ./lib --name "My Project"
```

When used as a library, ACE can incorporate project context:

```elixir
# Create a project and analyze multiple files
{:ok, result} = Ace.Analysis.Service.analyze_project(
  %{name: "My Project", base_path: "./lib", description: "Project description"},
  ["lib/module1.ex", "lib/module2.ex", "lib/module3.ex"],
  detect_relationships: true
)

# Access the results
%{
  project: project,
  analyses: analyses,
  relationships: relationships,
  cross_file_opportunities: opportunities
} = result

# Work with individual analyses, relationships, or opportunities
# ...
```

For comprehensive documentation on multi-file analysis and relationship visualization, see [docs/multi_file_analysis.md](docs/multi_file_analysis.md).

## CI/CD Integration

Integrate ACE into your CI/CD pipeline:

### GitHub Actions

```yaml
# .github/workflows/ace-optimize.yml
name: Code Optimization

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays
  workflow_dispatch:  # Allow manual triggers

jobs:
  optimize:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.14.0'
          otp-version: '25.0'
          
      - name: Install dependencies
        run: mix deps.get
        
      - name: Install ACE
        run: |
          git clone https://github.com/yourusername/ace.git
          cd ace
          mix deps.get
          mix escript.build
          sudo cp ace /usr/local/bin/
          
      - name: Run ACE optimization
        run: |
          ace run lib/**/*.ex --format json --output ace-results.json
          
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'Automated code optimization with ACE'
          title: 'Automated code optimization'
          body: |
            This PR contains automated code optimizations generated by ACE.
            
            Please review the changes carefully before merging.
          branch: ace-optimizations
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - optimize

code-optimization:
  stage: optimize
  image: elixir:1.14
  only:
    - schedules
    - web
  script:
    - mix deps.get
    - git clone https://github.com/yourusername/ace.git
    - cd ace && mix deps.get && mix escript.build
    - cp ace /usr/local/bin/
    - cd $CI_PROJECT_DIR
    - ace run lib/**/*.ex --auto-apply
    - git config --global user.email "ace-bot@example.com"
    - git config --global user.name "ACE Optimization Bot"
    - git checkout -b ace-optimizations-$CI_PIPELINE_ID
    - git add .
    - git commit -m "Automated code optimization with ACE" || echo "No changes to commit"
    - git push origin ace-optimizations-$CI_PIPELINE_ID
  artifacts:
    paths:
      - ace-results.json
```

## Advanced Configuration

### Configuration File

Create a `.ace.yaml` file for project-wide configuration:

```yaml
# AI provider configuration
ai_provider: "groq"
ai_model: "llama3-70b-8192"
api_key_env: "GROQ_API_KEY"

# Default analysis settings
default_focus_areas: 
  - performance
  - maintainability
  - security
default_severity_threshold: "medium"

# Default optimization settings
default_strategy: "auto"
auto_apply: false

# Output settings
default_format: "text"

# Custom rules
rules:
  - name: "no_long_functions"
    type: "maintainability"
    severity: "medium"
    description: "Functions should not exceed 30 lines"
    
  - name: "secure_password_handling"
    type: "security"
    severity: "high"
    description: "Passwords must be hashed before storage"

# Ignore patterns
ignore_patterns:
  - "test/**/*_test.exs"
  - "priv/static/**/*"
  - "deps/**/*"
```

### Environment Variables

Configure ACE with environment variables:

```bash
# AI provider configuration
export ACE_AI_PROVIDER=groq
export ACE_AI_MODEL=llama3-70b-8192
export GROQ_API_KEY=your-api-key

# Default settings
export ACE_DEFAULT_FOCUS_AREAS=performance,maintainability
export ACE_DEFAULT_SEVERITY_THRESHOLD=medium

# Run ACE with env var configuration
ace analyze lib/my_module.ex
```

### Project-Specific Extensions

Create project-specific extensions in your codebase:

```elixir
# In your project's code
defmodule MyProject.AceExtensions do
  # Define a project-specific analyzer
  Ace.define_analyzer :phoenix_controller_actions,
    focus_areas: ["maintainability", "performance"],
    severity_threshold: "medium",
    fn code, language ->
      if language == "elixir" && String.contains?(code, "use PhoenixController") do
        # Analyze Phoenix controller actions
        # ...
      else
        []
      end
    end
    
  # Define a project-specific strategy
  Ace.define_strategy :phoenix_optimizations,
    priority: ["performance"],
    fn opportunity, original_code ->
      # Optimize Phoenix-specific code
      # ...
    end
end

# Load the extensions in your application
defmodule MyProject.Application do
  use Application
  
  def start(_type, _args) do
    # Load ACE extensions
    Code.ensure_loaded(MyProject.AceExtensions)
    
    # Rest of your application startup
    # ...
  end
end
```

This concludes the usage guide for ACE. For more details, refer to the API documentation and architecture guide.