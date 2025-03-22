# Seeds file for ACE database

alias Ace.Repo
alias Ace.Core.Project
alias Ace.Core.Analysis
alias Ace.Core.Opportunity
alias Ace.Core.Optimization
alias Ace.Core.Evaluation
alias Ace.Core.Experiment
alias Ace.Core.Feedback
alias Ace.Core.EvolutionHistory
alias Ace.Core.EvolutionProposal

# Create a demo project
{:ok, project} = Repo.insert(%Project{
  name: "Demo Project",
  description: "A demonstration project for ACE",
  base_path: "/demo"
})

# Create a sample analysis
{:ok, analysis} = Repo.insert(%Analysis{
  project_id: project.id,
  file_path: "/demo/example.ex",
  language: "elixir",
  content: """
  defmodule Demo do
    def inefficient_sum(list) do
      Enum.reduce(list, 0, fn num, acc -> acc + num end)
    end
  end
  """,
  focus_areas: ["performance", "maintainability"],
  severity_threshold: "medium"
})

# Create a sample opportunity
{:ok, opportunity} = Repo.insert(%Opportunity{
  analysis_id: analysis.id,
  location: "line 3",
  type: "performance",
  description: "Inefficient sum implementation, consider using Enum.sum/1",
  severity: "medium",
  rationale: "Enum.sum/1 is a built-in function that is optimized for summing lists of numbers",
  suggested_change: "Replace with Enum.sum(list)"
})

# Create a sample optimization
{:ok, optimization} = Repo.insert(%Optimization{
  opportunity_id: opportunity.id,
  strategy: "standard",
  original_code: """
  defmodule Demo do
    def inefficient_sum(list) do
      Enum.reduce(list, 0, fn num, acc -> acc + num end)
    end
  end
  """,
  optimized_code: """
  defmodule Demo do
    def inefficient_sum(list) do
      Enum.sum(list)
    end
  end
  """,
  explanation: "Replaced manual reduction with the built-in Enum.sum/1 function which is more efficient and readable",
  status: "pending"
})

# Create a sample evaluation
{:ok, evaluation} = Repo.insert(%Evaluation{
  optimization_id: optimization.id,
  success: true,
  metrics: %{
    execution_time_original: 0.324,
    execution_time_optimized: 0.187,
    improvement_percentage: 42.3
  },
  report: """
  Evaluation successful. The optimized implementation is 42.3% faster than the original.
  Both implementations produce the same results on test inputs.
  """
})

# Create a sample experiment
{:ok, _experiment} = Repo.insert(%Experiment{
  evaluation_id: evaluation.id,
  setup_data: %{
    test_cases: [
      %{input: [1, 2, 3, 4, 5], expected_output: 15},
      %{input: [10, 20, 30], expected_output: 60}
    ]
  },
  results: %{
    test_cases_passed: 2,
    test_cases_total: 2,
    execution_times: [0.186, 0.188]
  },
  status: "completed"
})

# Add some feedback
feedback_source = "demo_feature"

# Add some negative feedback (scores 0-6)
for _ <- 1..8 do
  score = Enum.random(0..6)
  comment = Enum.random([
    "Too slow for my use case",
    "This feature is frustrating to use",
    "Could be improved significantly",
    "Performance is not acceptable",
    "Doesn't work well with large datasets"
  ])
  
  {:ok, _} = Repo.insert(%Feedback{
    score: score,
    comment: comment,
    source: feedback_source,
    user_id: "user_#{Enum.random(1..100)}",
    feature_id: "demo_module"
  })
end

# Add some neutral feedback (scores 7-8)
for _ <- 1..3 do
  score = Enum.random(7..8)
  comment = Enum.random([
    "Works fine most of the time",
    "Acceptable but could be better",
    "Generally good but has some issues",
    "Reasonable performance"
  ])
  
  {:ok, _} = Repo.insert(%Feedback{
    score: score,
    comment: comment,
    source: feedback_source,
    user_id: "user_#{Enum.random(1..100)}",
    feature_id: "demo_module"
  })
end

# Add a few positive feedback (scores 9-10)
for _ <- 1..2 do
  score = Enum.random(9..10)
  comment = Enum.random([
    "Great feature",
    "Works well for my needs", 
    "Very satisfied with this"
  ])
  
  {:ok, _} = Repo.insert(%Feedback{
    score: score,
    comment: comment,
    source: feedback_source,
    user_id: "user_#{Enum.random(1..100)}",
    feature_id: "demo_module"
  })
end

# Create an evolution history entry
{:ok, _} = Repo.insert(%EvolutionHistory{
  dsl_name: "Demo",
  date: ~U[2025-02-14 10:00:00Z],
  was_successful: false,
  metrics: %{
    "average_nps_before": 5.2
  }
})

# Create a proposal
{:ok, _} = Repo.insert(%EvolutionProposal{
  dsl_name: "Demo",
  proposed_code: """
  defmodule Demo do
    @moduledoc \"\"\"
    Optimized demonstration module
    \"\"\"
    
    @doc \"\"\"
    Efficiently sums a list of numbers using built-in Enum.sum/1
    
    ## Examples
        
        iex> Demo.inefficient_sum([1, 2, 3, 4, 5])
        15
        
    \"\"\"
    def inefficient_sum(list) do
      Enum.sum(list)
    end
    
    @doc \"\"\"
    Handles empty lists gracefully by returning 0
    \"\"\"
    def inefficient_sum([]), do: 0
  end
  """,
  status: "pending_review"
})

IO.puts "Seed data inserted successfully!"