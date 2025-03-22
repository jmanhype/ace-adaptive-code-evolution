defmodule Mix.Tasks.Ace.GenerateProposal do
  @moduledoc """
  Mix task to generate a test evolution proposal.

  This task creates a new proposal for testing the auto-apply feature.
  """
  use Mix.Task
  
  @shortdoc "Generates a test evolution proposal"
  
  @doc """
  Run the task to generate a test proposal.
  """
  def run(_) do
    # Ensure the application is started
    Mix.Task.run("app.start")
    
    alias Ace.Core.EvolutionProposal
    
    # Creating a test proposal for Demo module
    demo_module = "Demo"
    proposed_code = ~s"""
    defmodule Demo do
      @moduledoc \"\"\"
      A demo module with inefficient functions for demonstrating code evolution.
      This is a test proposal generated programmatically.
      \"\"\"
      
      @doc \"\"\"
      An inefficient sum function.
      Calculates the sum of numbers from 1 to n.
      \"\"\"
      def inefficient_sum(n) when is_integer(n) and n > 0 do
        # This was deliberately made inefficient for evolution purposes
        # Now with an optimization - using arithmetic formula
        n * (n + 1) / 2
      end
      
      @doc \"\"\"
      A function with deliberately poor performance to demonstrate evolution.
      Finds the nth Fibonacci number using recursive algorithm.
      \"\"\"
      def fibonacci(n) when is_integer(n) and n >= 0 do
        # A deliberately inefficient implementation of Fibonacci
        # Now with optimization - using pattern matching
        case n do
          0 -> 0
          1 -> 1
          n -> fibonacci(n-1) + fibonacci(n-2)
        end
      end
    end
    """
    
    attrs = %{
      dsl_name: demo_module,
      proposed_code: proposed_code
    }
    
    case EvolutionProposal.create(attrs) do
      {:ok, proposal} ->
        Mix.shell().info("Successfully created proposal with ID: #{proposal.id}")
        Mix.shell().info("Running auto-apply proposals task to test auto-processing...")
        Mix.Tasks.Ace.AutoApplyProposals.run([])
      {:error, changeset} ->
        Mix.shell().error("Failed to create proposal: #{inspect(changeset.errors)}")
    end
  end
end 