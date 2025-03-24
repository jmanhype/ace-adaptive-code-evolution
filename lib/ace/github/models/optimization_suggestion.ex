defmodule Ace.GitHub.Models.OptimizationSuggestion do
  @moduledoc """
  Schema and functions for code optimization suggestions.
  This module handles the storage and retrieval of optimizations suggested for code in PRs.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  
  alias Ace.Repo
  alias Ace.GitHub.Models.{OptimizationSuggestion, PullRequest, PRFile}
  
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "github_optimization_suggestions" do
    field :opportunity_type, :string
    field :location, :string
    field :description, :string
    field :severity, :string, default: "medium"
    field :original_code, :string
    field :optimized_code, :string
    field :explanation, :string
    field :status, :string, default: "pending" # pending, submitted, rejected, accepted
    field :comment_id, :integer
    field :metrics, :map, default: %{}
    
    # Relationships
    belongs_to :pull_request, PullRequest, foreign_key: :pr_id
    belongs_to :file, PRFile, foreign_key: :file_id
    
    timestamps()
  end
  
  @type t() :: %__MODULE__{
    id: binary() | nil,
    opportunity_type: String.t() | nil,
    location: String.t() | nil,
    description: String.t() | nil,
    severity: String.t() | nil,
    original_code: String.t() | nil,
    optimized_code: String.t() | nil,
    explanation: String.t() | nil,
    status: String.t() | nil,
    comment_id: integer() | nil,
    metrics: map() | nil,
    pr_id: binary() | nil,
    file_id: binary() | nil,
    pull_request: PullRequest.t() | Ecto.Association.NotLoaded.t() | nil,
    file: PRFile.t() | Ecto.Association.NotLoaded.t() | nil,
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }
  
  @doc """
  Creates a changeset for an optimization suggestion.
  
  ## Parameters
    - suggestion: The suggestion schema to change (nil for a new one)
    - attrs: The attributes to change or create with
  
  ## Returns
    - A changeset
  """
  @spec changeset(OptimizationSuggestion.t() | nil, map()) :: Ecto.Changeset.t()
  def changeset(suggestion, attrs) do
    suggestion
    |> Ecto.Changeset.cast(attrs, [
      :pr_id, :file_id, :opportunity_type, :location, :description,
      :severity, :original_code, :optimized_code, :explanation,
      :status, :comment_id, :metrics
    ])
    |> Ecto.Changeset.validate_required([
      :pr_id, :file_id, :opportunity_type, :location, 
      :description, :original_code, :optimized_code
    ])
    |> Ecto.Changeset.foreign_key_constraint(:pr_id)
    |> Ecto.Changeset.foreign_key_constraint(:file_id)
  end
  
  @doc """
  Creates a new optimization suggestion.
  
  ## Parameters
    - attrs: The attributes to create with
    
  ## Returns
    - {:ok, suggestion} on success
    - {:error, changeset} on failure
  """
  @spec create(map()) :: {:ok, OptimizationSuggestion.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %OptimizationSuggestion{}
    |> changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates an optimization suggestion's status.
  
  ## Parameters
    - id: The suggestion ID
    - status: The new status
    - comment_id: Optional GitHub comment ID
    
  ## Returns
    - {:ok, suggestion} on success
    - {:error, changeset} on failure
    - {:error, :not_found} if suggestion not found
  """
  @spec update_status(binary(), String.t(), integer() | nil) :: 
    {:ok, OptimizationSuggestion.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found}
  def update_status(id, status, comment_id \\ nil) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      suggestion ->
        attrs = if comment_id do
          %{status: status, comment_id: comment_id}
        else
          %{status: status}
        end
        
        suggestion
        |> changeset(attrs)
        |> Repo.update()
    end
  end
  
  @doc """
  Gets all suggestions for a pull request.
  
  ## Parameters
    - pr_id: The pull request ID
    
  ## Returns
    - List of optimization suggestions
  """
  @spec get_for_pr(binary()) :: [OptimizationSuggestion.t()]
  def get_for_pr(pr_id) do
    from(s in __MODULE__, where: s.pr_id == ^pr_id)
    |> Repo.all()
  end
  
  @doc """
  Gets all suggestions for a pull request, with better naming consistency.
  Alias for get_for_pr.
  
  ## Parameters
    - pr_id: The pull request ID
    
  ## Returns
    - List of optimization suggestions
  """
  @spec get_by_pr_id(binary()) :: [OptimizationSuggestion.t()]
  def get_by_pr_id(pr_id) do
    get_for_pr(pr_id)
  end
  
  @doc """
  Gets all suggestions for a specific file.
  
  ## Parameters
    - file_id: The file ID
    
  ## Returns
    - List of optimization suggestions
  """
  @spec get_for_file(binary()) :: [OptimizationSuggestion.t()]
  def get_for_file(file_id) do
    from(s in __MODULE__, where: s.file_id == ^file_id)
    |> Repo.all()
  end
  
  @doc """
  Gets all suggestions with a specific status.
  
  ## Parameters
    - status: The status to filter by
    
  ## Returns
    - List of optimization suggestions
  """
  @spec get_by_status(String.t()) :: [OptimizationSuggestion.t()]
  def get_by_status(status) do
    from(s in __MODULE__, where: s.status == ^status)
    |> Repo.all()
  end
  
  @spec get_by_id(integer()) :: t() | nil
  def get_by_id(id) do
    Ace.Repo.get(__MODULE__, id)
  end
  
  @doc """
  Lists all optimization suggestions for a specific file.
  
  ## Parameters
    - file_id: The ID of the file to get suggestions for
    
  ## Returns
    - List of optimization suggestions
  """
  @spec list_by_file(integer()) :: [t()]
  def list_by_file(file_id) do
    from(s in __MODULE__, where: s.file_id == ^file_id)
    |> Ace.Repo.all()
  end
end 