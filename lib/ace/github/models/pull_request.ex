defmodule Ace.GitHub.Models.PullRequest do
  @moduledoc """
  Schema and functions for GitHub pull requests.
  This module manages pull request data received from GitHub webhooks.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  
  alias Ace.Repo
  alias Ace.GitHub.Models.{PullRequest, PRFile, OptimizationSuggestion}
  
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "github_pull_requests" do
    field :pr_id, :integer
    field :number, :integer
    field :title, :string
    field :html_url, :string
    field :repo_name, :string
    field :head_sha, :string
    field :base_sha, :string
    field :status, :string, default: "pending" # pending, processing, optimized, commented, error
    field :user, :string
    
    # Relationships
    has_many :files, PRFile, foreign_key: :pr_id
    has_many :optimization_suggestions, OptimizationSuggestion, foreign_key: :pr_id
    
    timestamps()
  end
  
  @type t() :: %__MODULE__{
    id: binary() | nil,
    pr_id: {:integer, 8} | nil,
    number: integer() | nil,
    title: String.t() | nil,
    repo_name: String.t() | nil,
    user: String.t() | nil,
    html_url: String.t() | nil,
    base_sha: String.t() | nil,
    head_sha: String.t() | nil,
    status: String.t() | nil,
    files: [PRFile.t()] | Ecto.Association.NotLoaded.t() | nil,
    optimization_suggestions: [OptimizationSuggestion.t()] | Ecto.Association.NotLoaded.t() | nil,
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }
  
  @doc """
  Creates a changeset for a GitHub pull request.
  
  ## Parameters
    - pr: The pull request schema to change (nil for a new one)
    - attrs: The attributes to change or create with
  
  ## Returns
    - A changeset
  """
  @spec changeset(PullRequest.t() | nil, map()) :: Ecto.Changeset.t()
  def changeset(pr, attrs) do
    pr
    |> Ecto.Changeset.cast(attrs, [
      :pr_id, :number, :title, :html_url, 
      :repo_name, :head_sha, :base_sha, :status, :user
    ])
    |> Ecto.Changeset.validate_required([:pr_id, :number, :html_url, :repo_name])
    |> Ecto.Changeset.unique_constraint([:pr_id, :repo_name], name: :github_pr_unique_index)
  end
  
  @doc """
  Creates or updates a pull request.
  
  ## Parameters
    - attrs: The attributes to create or update with
    
  ## Returns
    - {:ok, pull_request} on success
    - {:error, changeset} on failure
  """
  @spec upsert(map()) :: {:ok, PullRequest.t()} | {:error, Ecto.Changeset.t()}
  def upsert(attrs) do
    case Repo.get_by(__MODULE__, pr_id: attrs.pr_id, repo_name: attrs.repo_name) do
      nil -> %PullRequest{}
      pr -> pr
    end
    |> changeset(attrs)
    |> Repo.insert_or_update()
  end
  
  @doc """
  Updates the status of a pull request.
  
  ## Parameters
    - id: The database UUID of the pull request
    - status: The new status string
    
  ## Returns
    - {:ok, pull_request} on success
    - {:error, changeset} on failure
  """
  @spec update_status(binary(), String.t()) :: {:ok, PullRequest.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found}
  def update_status(id, status) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      pr ->
        pr
        |> changeset(%{status: status})
        |> Repo.update()
    end
  end
  
  @doc """
  Gets a list of pull requests by status.
  
  ## Parameters
    - status: The status to filter by
    
  ## Returns
    - List of pull requests
  """
  @spec list_by_status(String.t()) :: [PullRequest.t()]
  def list_by_status(status) do
    from(p in __MODULE__, where: p.status == ^status)
    |> Repo.all()
  end
  
  @doc """
  Gets a pull request by PR ID and repo name.
  
  ## Parameters
    - pr_id: The GitHub pull request ID
    - repo_name: The repository name
    
  ## Returns
    - The pull request or nil
  """
  @spec get_by_pr_id_and_repo(integer(), String.t()) :: PullRequest.t() | nil
  def get_by_pr_id_and_repo(pr_id, repo_name) do
    Repo.get_by(__MODULE__, pr_id: pr_id, repo_name: repo_name)
  end
  
  @doc """
  Gets a pull request with preloaded files and optimization suggestions.
  
  ## Parameters
    - id: The internal database ID
    
  ## Returns
    - The pull request with preloaded associations or nil
  """
  @spec get_with_files_and_suggestions(binary()) :: PullRequest.t() | nil
  def get_with_files_and_suggestions(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:files, :optimization_suggestions])
  end

  @doc """
  Updates a pull request with the given changes.

  ## Parameters
    - pull_request: The pull request to update.
    - attrs: Map of attributes to update.

  ## Returns
    - `{:ok, pull_request}` on success
    - `{:error, changeset}` on failure
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(%__MODULE__{} = pull_request, attrs) do
    pull_request
    |> changeset(attrs)
    |> Ace.Repo.update()
  end

  @doc """
  Lists all pull requests ordered by most recent first.

  Returns a list of pull requests.
  """
  @spec list_all() :: [t()]
  def list_all do
    Ace.Repo.all(from p in __MODULE__, order_by: [desc: p.updated_at])
  end

  @doc """
  Gets a pull request by ID.

  Returns the pull request or nil if not found.
  """
  @spec get(integer()) :: t() | nil
  def get(id) do
    Ace.Repo.get(__MODULE__, id)
  end
  
  @doc """
  Gets a pull request by its GitHub PR ID.

  ## Parameters
    - github_id: The GitHub pull request ID

  ## Returns
    - The pull request or nil if not found
  """
  @spec get_by_github_id(integer()) :: t() | nil
  def get_by_github_id(github_id) do
    Ace.Repo.get_by(__MODULE__, pr_id: github_id)
  end
end 