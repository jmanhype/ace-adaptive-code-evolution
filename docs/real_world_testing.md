# ACE: Testing with Real-World Codebases

This guide outlines approaches, tools, and best practices for testing ACE with larger, real-world codebases to ensure robust performance and accuracy across different project types and scales.

## Table of Contents

1. [Introduction](#introduction)
2. [Test Methodology](#test-methodology)
3. [Test Corpus](#test-corpus)
4. [Performance Benchmarking](#performance-benchmarking)
5. [Accuracy Evaluation](#accuracy-evaluation)
6. [Resource Utilization](#resource-utilization)
7. [Implementation Guide](#implementation-guide)
8. [Analysis Dashboard](#analysis-dashboard)
9. [Continuous Integration](#continuous-integration)
10. [Future Improvements](#future-improvements)

## Introduction

Testing ACE with large, real-world codebases is crucial to:

- Verify performance at scale
- Ensure accuracy across different programming paradigms
- Identify edge cases not covered by unit tests
- Measure and optimize resource utilization
- Build confidence in ACE's real-world applicability

This document outlines a comprehensive approach to real-world codebase testing.

## Test Methodology

### Three-Phase Testing Approach

1. **Controlled Testing**: Begin with known, open-source codebases with clear documentation and established patterns

2. **Directed Testing**: Specifically test problematic code patterns and edge cases across multiple projects

3. **Blind Testing**: Analyze unfamiliar codebases to simulate real-world usage

### Metrics to Capture

For each codebase tested:

- **Performance**: Time to complete analysis, optimization, and evaluation
- **Resource Usage**: Memory, CPU, and network utilization
- **Accuracy**: Correctness of identified opportunities (manually verified)
- **Relevance**: Usefulness of suggested optimizations 
- **False Positives/Negatives**: Missed opportunities or incorrectly identified issues

## Test Corpus

A diverse collection of codebases should be selected based on the following criteria:

### Criteria for Selection

- **Size Range**: Small (1K-10K LOC), Medium (10K-100K LOC), Large (100K+ LOC)
- **Language Coverage**: Representative projects in each supported language
- **Paradigm Variety**: Functional, object-oriented, procedural, mixed paradigms
- **Architectural Diversity**: Monoliths, microservices, libraries, applications
- **Code Quality Spectrum**: Well-maintained projects and those with known issues

### Recommended Open Source Projects

#### Elixir
- **Phoenix**: Web framework (Medium/Large, ~60K LOC)
- **Ecto**: Database library (Medium, ~30K LOC)
- **Credo**: Static code analysis (Medium, ~15K LOC)
- **Nerves**: Embedded systems framework (Large, ~100K+ LOC across packages)

#### JavaScript
- **Express**: Web framework (Medium, ~15K LOC)
- **React**: UI library (Large, ~150K LOC)
- **Lodash**: Utility library (Medium, ~25K LOC)
- **Vue.js**: Frontend framework (Medium, ~30K LOC)

#### Python
- **Flask**: Web framework (Medium, ~30K LOC)
- **Requests**: HTTP library (Small, ~8K LOC)
- **Pandas**: Data analysis (Large, ~200K LOC)
- **Django**: Web framework (Large, ~250K LOC)

#### Ruby
- **Rails**: Web framework (Large, ~300K LOC)
- **RSpec**: Testing framework (Medium, ~40K LOC)
- **Jekyll**: Static site generator (Medium, ~25K LOC)

#### Go
- **Hugo**: Static site generator (Medium, ~50K LOC)
- **etcd**: Distributed key-value store (Large, ~150K LOC)
- **gin**: Web framework (Medium, ~15K LOC)

### Custom Test Repositories

Create specific repositories to test ACE's capabilities:

1. **Cross-Language Monorepo**: Contains modules in multiple languages that interact
2. **Deliberately Problematic Codebase**: Includes common anti-patterns and issues
3. **Legacy Migration Project**: Simulates modernizing older code
4. **Highly Coupled System**: Tests relationship detection and visualization
5. **Microservices Ecosystem**: Tests analysis across service boundaries

## Performance Benchmarking

### Metrics

Measure and compare performance across different codebases:

- **Analysis Time**: Time to complete code analysis per 1K lines of code
- **Relationship Detection Time**: Time to identify and classify file relationships
- **Memory Usage**: Peak memory consumption during analysis
- **Scalability Curve**: How performance scales with codebase size

### Benchmark Implementation

Create a dedicated benchmarking module:

```elixir
defmodule Ace.Benchmarks.RealWorldCodebases do
  @moduledoc """
  Benchmarks ACE performance on real-world codebases.
  """
  
  @doc """
  Runs analysis on a real-world codebase and captures performance metrics.
  """
  def benchmark_codebase(repo_url, options \\ []) do
    # Configure benchmark
    clone_path = options[:clone_path] || tmp_clone_path()
    languages = options[:languages] || ["elixir", "javascript", "python", "ruby", "go"]
    focus_areas = options[:focus_areas] || ["performance", "maintainability"]
    
    # Clone repository
    {clone_time, _} = :timer.tc(fn -> 
      clone_repository(repo_url, clone_path)
    end)
    
    # Gather codebase stats
    stats = gather_codebase_stats(clone_path, languages)
    
    # Set up benchmark metrics collection
    metrics = %{
      codebase: repo_url,
      clone_time_ms: clone_time / 1000,
      stats: stats,
      analysis_metrics: %{},
      relationship_metrics: %{},
      opportunity_metrics: %{},
      memory_usage: %{}
    }
    
    # Run analysis with memory tracking
    {metrics, result} = with_memory_tracking(metrics, fn ->
      run_analysis(clone_path, languages, focus_areas)
    end)
    
    # Compute derived metrics
    metrics = compute_derived_metrics(metrics, result)
    
    # Record results
    save_benchmark_results(metrics)
    
    # Return metrics
    metrics
  end
  
  # Helper functions implementation...
end
```

## Accuracy Evaluation

### Manual Verification Process

1. Manually review a sample of identified opportunities:
   - 100% of critical/high-severity opportunities
   - 50% of medium-severity opportunities 
   - 10% of low-severity opportunities

2. For each opportunity, evaluate:
   - Is it a genuine issue? (True/False Positive)
   - Is the severity appropriate? (Correct/Incorrect Severity)
   - Is the suggested optimization valid? (Valid/Invalid Suggestion)
   - Would a human expert identify this? (Expert Agreement)

3. Document results in a structured format for analysis.

### Expert Panel Review

Assemble a panel of language experts to review ACE's output on selected codebases:

1. Provide experts with:
   - Original code
   - ACE-identified opportunities
   - ACE-suggested optimizations

2. Collect expert feedback:
   - Missed opportunities (False Negatives)
   - Disagreements with ACE's analysis
   - Alternative optimization suggestions
   - Overall assessment of ACE's value

### Automated Accuracy Verification

For opportunities with clear correctness requirements:

1. **Compile Testing**: Ensure optimized code compiles
2. **Unit Test Verification**: Run project's tests against optimized code
3. **Performance Validation**: Measure performance improvements for performance-focused opportunities
4. **Static Analysis**: Run language-specific static analyzers before and after optimization

## Resource Utilization

### Memory Usage Analysis

1. Track memory usage across the analysis pipeline:
   - During file parsing
   - During relationship detection
   - During AI-powered optimization
   - Peak memory usage

2. Identify memory bottlenecks:
   - Components with highest memory usage
   - Memory leaks or accumulation issues
   - Scaling characteristics with codebase size

### Implementation

```elixir
def with_memory_tracking(metrics, func) do
  # Get initial memory stats
  initial_stats = :erlang.memory()
  
  # Start monitoring process memory
  monitoring_pid = spawn_monitor_memory()
  
  # Execute the function
  result = func.()
  
  # Stop monitoring and collect peak memory usage
  peak_memory = stop_monitor_memory(monitoring_pid)
  
  # Get final memory stats
  final_stats = :erlang.memory()
  
  # Calculate memory deltas
  memory_metrics = %{
    total_used_kb: div(final_stats[:total], 1024),
    delta_total_kb: div(final_stats[:total] - initial_stats[:total], 1024),
    peak_used_kb: div(peak_memory, 1024)
  }
  
  # Update metrics
  updated_metrics = Map.put(metrics, :memory_usage, memory_metrics)
  
  {updated_metrics, result}
end
```

## Implementation Guide

### 1. Test Infrastructure Setup

Create a dedicated test infrastructure:

```elixir
# In mix.exs
def project do
  [
    # ...
    aliases: [
      # ...
      "test.real_world": ["run test/real_world/run_tests.exs"],
    ]
  ]
end
```

Directory structure:

```
test/
  real_world/
    run_tests.exs               # Main runner
    codebases.json              # Test corpus configuration
    benchmarks/                 # Performance benchmarking code
    accuracy/                   # Accuracy evaluation tools
    results/                    # Test results storage
      <timestamp>/              # One directory per test run
        metrics.json            # Metrics summary
        <codebase-1>/           # Results for each codebase
          analysis_results.json
          opportunities.json
          relationships.json
          resource_metrics.json
```

### 2. Codebase Runner

Create a module to run tests on a codebase:

```elixir
defmodule Ace.RealWorld.CodebaseRunner do
  @moduledoc """
  Runs ACE on a real-world codebase and collects metrics.
  """
  
  def run(codebase, options \\ []) do
    # Prepare test directory
    test_dir = prepare_test_directory(codebase, options)
    
    # Clone repository if remote
    clone_if_needed(codebase, test_dir)
    
    # Run analysis
    results = %{}
    
    # Step 1: Individual file analysis
    {time, file_results} = :timer.tc(fn ->
      Ace.analyze_directory(test_dir)
    end)
    results = Map.put(results, :file_analysis, %{
      time_ms: time / 1000,
      file_count: length(file_results),
      results: file_results
    })
    
    # Step 2: Relationship detection
    {time, relationship_results} = :timer.tc(fn ->
      Ace.detect_relationships(file_results)
    end)
    results = Map.put(results, :relationships, %{
      time_ms: time / 1000,
      relationship_count: length(relationship_results),
      results: relationship_results
    })
    
    # Step 3: Cross-file analysis
    {time, opportunity_results} = :timer.tc(fn ->
      Ace.analyze_cross_file(file_results, relationship_results)
    end)
    results = Map.put(results, :opportunities, %{
      time_ms: time / 1000,
      opportunity_count: length(opportunity_results),
      results: opportunity_results
    })
    
    # Save results
    save_results(codebase, results, test_dir)
    
    # Return results
    results
  end
  
  # Helper functions...
end
```

### 3. Recording and Analyzing Results

Create data collection and analysis utilities:

```elixir
defmodule Ace.RealWorld.ResultAnalyzer do
  @moduledoc """
  Analyzes results from real-world codebase tests.
  """
  
  def analyze_results(results_dir) do
    # Load all test results
    all_results = load_all_results(results_dir)
    
    # Compute aggregated metrics
    metrics = compute_aggregated_metrics(all_results)
    
    # Generate report
    report = generate_report(metrics, all_results)
    
    # Save report
    save_report(report, results_dir)
    
    # Return report
    report
  end
  
  # Helper functions...
end
```

## Analysis Dashboard

Create a dashboard to visualize test results:

### 1. Dashboard Structure

```elixir
defmodule Ace.RealWorld.Dashboard do
  use Phoenix.LiveView
  
  def mount(_params, _session, socket) do
    # Load latest test results
    latest_results = load_latest_results()
    
    socket =
      socket
      |> assign(:results, latest_results)
      |> assign(:selected_codebase, nil)
      |> assign(:view_mode, :summary)
    
    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class="real-world-dashboard">
      <header>
        <h1>ACE Real-World Testing Dashboard</h1>
      </header>
      
      <div class="dashboard-content">
        <aside class="sidebar">
          <h2>Test Runs</h2>
          <ul class="test-run-list">
            <%= for run <- @results.test_runs do %>
              <li class="test-run-item">
                <button phx-click="select-run" phx-value-id={run.id}>
                  <%= run.timestamp %> (<%= run.codebase_count %> codebases)
                </button>
              </li>
            <% end %>
          </ul>
          
          <h2>Codebases</h2>
          <ul class="codebase-list">
            <%= for codebase <- @results.current_run.codebases do %>
              <li class="codebase-item">
                <button phx-click="select-codebase" phx-value-id={codebase.id}>
                  <%= codebase.name %> (<%= codebase.language %>)
                </button>
              </li>
            <% end %>
          </ul>
        </aside>
        
        <main class="main-content">
          <%= case @view_mode do %>
            <% :summary -> %>
              <div class="summary-view">
                <div class="metrics-cards">
                  <!-- Performance metrics -->
                </div>
                
                <div class="charts">
                  <!-- Visualization of test results -->
                </div>
              </div>
              
            <% :codebase_detail -> %>
              <div class="codebase-detail">
                <!-- Detailed view of selected codebase -->
              </div>
              
            <% :comparison -> %>
              <div class="comparison-view">
                <!-- Comparison between runs or codebases -->
              </div>
          <% end %>
        </main>
      </div>
    </div>
    """
  end
  
  # Event handlers and helper functions...
end
```

### 2. Key Metrics to Display

- **Performance Summary**:
  - Analysis time per 1K lines of code
  - Memory usage per 1K lines of code
  - Comparison to previous runs
  
- **Accuracy Metrics**:
  - True positive rate (manually verified)
  - False positive rate (manually verified)
  - Expert agreement percentage
  
- **Scaling Visualization**:
  - Graph of performance vs. codebase size
  - Graph of memory usage vs. codebase size
  
- **Codebase Details**:
  - File count by language
  - Relationship count by type
  - Opportunity count by severity and type

## Continuous Integration

### 1. Scheduled Testing

Set up a GitHub Actions workflow to run tests on a schedule:

```yaml
# .github/workflows/real-world-tests.yml
name: Real-World Codebase Tests

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sundays
  workflow_dispatch:  # Allow manual trigger

jobs:
  test-real-world:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.14.0'
          otp-version: '25.0'
          
      - name: Cache test codebases
        uses: actions/cache@v3
        with:
          path: test/real_world/cache
          key: ${{ runner.os }}-test-codebases
          
      - name: Install dependencies
        run: mix deps.get
        
      - name: Run real-world tests
        run: mix test.real_world
        env:
          ACE_AI_PROVIDER: ${{ secrets.ACE_AI_PROVIDER }}
          ACE_AI_MODEL: ${{ secrets.ACE_AI_MODEL }}
          ACE_API_KEY: ${{ secrets.ACE_API_KEY }}
          
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: real-world-test-results
          path: test/real_world/results/latest
```

### 2. Results Tracking

Track results over time to detect regressions:

```elixir
defmodule Ace.RealWorld.ResultsTracker do
  @moduledoc """
  Tracks real-world test results over time and detects regressions.
  """
  
  def track_results(current_results) do
    # Load historical results
    historical_results = load_historical_results()
    
    # Compare current with historical
    comparison = compare_with_historical(current_results, historical_results)
    
    # Detect regressions
    regressions = detect_regressions(comparison)
    
    # Save current results to history
    save_to_history(current_results)
    
    # Return comparison and regressions
    %{
      comparison: comparison,
      regressions: regressions
    }
  end
  
  # Helper functions...
end
```

## Future Improvements

### Recommended Next Steps

1. **Automatic Test Corpus Update**:
   - Periodically update test repositories
   - Track latest releases of open-source projects
   - Automatically re-run tests when dependencies change

2. **Distributed Testing**:
   - Split testing across multiple machines
   - Create a test worker pool for parallel execution
   - Implement test sharding for large codebases

3. **Feedback Loop Integration**:
   - Allow ACE users to submit their codebases for analysis
   - Collect anonymized performance and accuracy metrics
   - Use feedback to improve ACE's algorithms

4. **Competitive Benchmarking**:
   - Compare ACE against similar tools
   - Establish industry benchmarks
   - Highlight ACE's strengths and areas for improvement

### Implementation Plan

1. **Phase 1: Core Infrastructure** (1-2 weeks)
   - Set up test corpus with 5-10 diverse codebases
   - Implement basic benchmarking
   - Create initial results dashboard

2. **Phase 2: Metrics and Analysis** (2-3 weeks)
   - Implement comprehensive metrics collection
   - Create analysis and visualization tools
   - Set up continuous integration

3. **Phase 3: Accuracy Verification** (3-4 weeks)
   - Develop accuracy verification methodology
   - Recruit expert panel
   - Create accuracy assessment tools

4. **Phase 4: Scaling and Optimization** (2-3 weeks)
   - Optimize ACE for large codebases
   - Implement distributed testing
   - Refine metrics and reporting

## Conclusion

Testing ACE with real-world codebases is essential for ensuring its practical utility and performance. By implementing this comprehensive testing approach, we can:

1. Build confidence in ACE's capabilities with large, complex codebases
2. Continuously improve performance and accuracy
3. Identify and address edge cases not covered by unit tests
4. Demonstrate ACE's value proposition with real-world examples

The investment in real-world testing will directly translate to a more robust, reliable, and useful tool for code optimization.