defmodule Ace.Evolution.Service do
  @moduledoc """
  Main service coordinating the self-evolution process.
  This integrates feedback collection, optimization generation, and proposal review.
  """
  require Logger
  import Ecto.Query
  
  alias Ace.Core.{
    Feedback, 
    EvolutionHistory, 
    EvolutionProposal, 
    Optimization
  }
  alias Ace.Evolution.Notification
  alias Ace.Infrastructure.AI.Orchestrator
  
  @doc """
  Checks if a module/feature should be evolved based on feedback.
  
  ## Parameters
    
    - `module_name`: Module name (atom or string)
    - `feedback_source`: Source identifier for the feedback
    - `threshold`: NPS threshold below which evolution should be triggered (default: 7.0)
  
  ## Returns
  
    - `{:ok, should_evolve}`: Boolean indicating if evolution should happen
    - `{:error, reason}`: If checking fails
  """
  def should_evolve?(module_name, feedback_source, threshold \\ 7.0) do
    # Get average NPS score for this module/feature
    avg_score = get_average_nps(feedback_source)
    
    # Get module name as string
    module_string = if is_atom(module_name), 
      do: Atom.to_string(module_name), 
      else: module_name
      
    # Check if we have enough feedback
    feedback_count = get_feedback_count(feedback_source)
    
    if feedback_count >= 10 do
      # Only evolve if score is below threshold - handle both float and Decimal
      avg_score_float = 
        if avg_score != nil do
          case avg_score do
            %Decimal{} -> Decimal.to_float(avg_score)
            _ -> avg_score
          end
        else
          nil
        end
      should_evolve = avg_score_float != nil && avg_score_float < threshold
      recent_attempts = get_recent_evolution_attempts(module_string)
      
      # Don't evolve if we've attempted recently
      if should_evolve && recent_attempts == 0 do
        {:ok, true}
      else
        {:ok, false}
      end
    else
      # Not enough feedback yet
      {:ok, false}
    end
  end
  
  @doc """
  Starts the evolution process for a module.
  
  ## Parameters
    
    - `module_name`: Module name (atom or string)
    - `source_code`: Current source code of the module
    - `feedback_source`: Source identifier for the feedback
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, proposal}`: The created evolution proposal
    - `{:error, reason}`: If evolution fails
  """
  def evolve(module_name, source_code, feedback_source, options \\ []) do
    # Get module name as string
    module_string = if is_atom(module_name), 
      do: Atom.to_string(module_name), 
      else: module_name
    
    # Get feedback context
    feedback_summary = get_feedback_summary(feedback_source)
    
    # Get evolution history
    evolution_history = EvolutionHistory.get_evolution_context(module_string)
    
    # Generate optimization
    with {:ok, optimization_data} <- generate_optimization(
           module_string,
           source_code,
           feedback_summary,
           evolution_history,
           options
         ),
         # Create a proposal
         {:ok, proposal} <- EvolutionProposal.create(%{
           dsl_name: module_string,
           proposed_code: optimization_data.optimized_code
         }) do
      
      # Notify team about proposal (if notification is enabled)
      if Keyword.get(options, :notify, true) do
        Notification.notify_about_proposal(proposal.id)
      end
      
      # Record the evolution attempt - make sure module_string is atom compatible
      module_atom = if is_atom(module_name), do: module_name, else: String.to_atom(module_name)
      EvolutionHistory.record_attempt(module_atom, false)
      
      {:ok, proposal}
    end
  end
  
  @doc """
  Automatically evolves modules based on feedback.
  
  ## Parameters
    
    - `modules`: List of module configurations to check:
      - `:module` - Module name (atom)
      - `:feedback_source` - Source identifier for feedback
      - `:threshold` - Optional NPS threshold (defaults to 7.0)
      - `:file_path` - Optional explicit file path of the module
    - `options`: Additional options for the evolution process
  
  ## Returns
  
    - `{:ok, results}`: List of evolution results for each module
    - `{:error, reason}`: If the process fails
  """
  def auto_evolve(modules, options \\ []) do
    results = Enum.map(modules, fn module_config ->
      module_name = module_config[:module]
      feedback_source = module_config[:feedback_source]
      threshold = module_config[:threshold] || 7.0
      file_path = module_config[:file_path]
      
      with {:ok, should_evolve} <- should_evolve?(module_name, feedback_source, threshold),
           true <- should_evolve,
           {:ok, source_code} <- get_module_source(module_name, file_path),
           {:ok, proposal} <- evolve(module_name, source_code, feedback_source, options) do
        {:ok, %{module: module_name, proposal_id: proposal.id}}
      else
        {:ok, false} -> 
          {:ok, %{module: module_name, status: :skipped, reason: :no_evolution_needed}}
        {:error, reason} -> 
          {:error, %{module: module_name, reason: reason}}
      end
    end)
    
    # Overall success if at least one module was successfully evolved
    if Enum.any?(results, fn
      {:ok, %{proposal_id: _}} -> true
      _ -> false
    end) do
      {:ok, results}
    else
      {:ok, results}  # Still return :ok with the results
    end
  end
  
  @doc """
  Applies an evolution proposal automatically.
  
  This should only be used if autonomous evolution is enabled in the configuration.
  """
  def auto_apply_proposal(proposal_id, options \\ []) do
    autonomous_deploy = Application.get_env(:ace, :autonomous_deploy, false)
    
    if autonomous_deploy do
      # First approve the proposal automatically
      reviewer_id = "AutoEvolution"
      comments = "Automatically approved by the system based on configuration."
      
      with {:ok, proposal} <- EvolutionProposal.approve(proposal_id, reviewer_id, comments),
           {:ok, version} <- EvolutionProposal.apply_proposal(proposal.id) do
        {:ok, %{proposal_id: proposal.id, version: version}}
      end
    else
      {:error, :autonomous_deploy_disabled}
    end
  end
  
  # Private helpers
  
  defp get_average_nps(feedback_source) do
    Feedback.average_score(source: feedback_source)
  end
  
  defp get_feedback_count(feedback_source) do
    Feedback
    |> where([f], f.source == ^feedback_source)
    |> Ace.Repo.aggregate(:count, :id)
  end
  
  defp get_feedback_summary(feedback_source) do
    # Get NPS distribution
    nps = Feedback.nps_distribution(source: feedback_source)
    
    # Get recent comments
    recent_comments = Feedback
    |> where([f], f.source == ^feedback_source and not is_nil(f.comment))
    |> order_by([f], desc: f.inserted_at)
    |> limit(10)
    |> select([f], %{score: f.score, comment: f.comment})
    |> Ace.Repo.all()
    
    %{
      nps_score: nps.nps_score,
      total_feedback: nps.total,
      detractors: nps.detractors.count,
      passives: nps.passive.count,
      promoters: nps.promoters.count,
      recent_comments: recent_comments
    }
  end
  
  defp get_recent_evolution_attempts(module_name) do
    # Get count of evolution attempts in the last 24 hours
    one_day_ago = DateTime.utc_now() |> DateTime.add(-86400, :second)
    
    EvolutionHistory
    |> where([h], h.dsl_name == ^module_name and h.date >= ^one_day_ago)
    |> Ace.Repo.aggregate(:count, :id)
  end
  
  defp get_module_source(module_name, file_path \\ nil) do
    path = if file_path do
      file_path
    else
      # Convert module name to file path
      module_name
      |> Atom.to_string()
      |> String.replace("Elixir.", "")
      |> String.split(".")
      |> Enum.map(&Macro.underscore/1)
      |> (fn parts ->
        first = List.first(parts)
        rest = Enum.slice(parts, 1..-1)
        ["lib", first | rest]
      end).()
      |> Path.join()
      |> Kernel.<>(".ex")
    end
    
    if File.exists?(path) do
      File.read(path)
    else
      {:error, :file_not_found}
    end
  end
  
  defp generate_optimization(module_name, source_code, feedback, history, options) do
    # Use our simplified AI service for evolution
    alias Ace.Evolution.SimpleAIService
    
    # For debugging
    history_str = format_history(history)
    Logger.debug("Generating optimization for #{module_name} with NPS score: #{feedback.nps_score}")
    Logger.debug("History: #{history_str}")
    
    # Call the SimpleAIService
    SimpleAIService.generate_optimization(source_code, feedback)
  end
  
  defp format_comments(comments) do
    comments
    |> Enum.map(fn %{score: score, comment: comment} ->
      "- Score #{score}/10: \"#{comment}\""
    end)
    |> Enum.join("\n")
  end
  
  defp format_history([]), do: "No previous evolution attempts."
  
  defp format_history(history) do
    history
    |> Enum.map(fn entry ->
      status = if entry.was_successful, do: "successful", else: "unsuccessful"
      date = Calendar.strftime(entry.date, "%Y-%m-%d")
      "- #{date}: #{status} evolution attempt"
    end)
    |> Enum.join("\n")
  end
end