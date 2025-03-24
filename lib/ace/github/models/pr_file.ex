defmodule Ace.GitHub.Models.PRFile do
  @moduledoc """
  Schema for a file in a GitHub pull request.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  
  alias Ace.Repo
  alias Ace.GitHub.Models.{PullRequest, PRFile}
  
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  
  schema "github_pr_files" do
    field :filename, :string
    field :status, :string
    field :language, :string
    field :content, :string
    field :additions, :integer
    field :deletions, :integer
    field :changes, :integer
    field :patch, :string
    
    belongs_to :pull_request, PullRequest, foreign_key: :pr_id
    
    timestamps()
  end
  
  @type t() :: %__MODULE__{
    id: binary() | nil,
    filename: String.t() | nil,
    status: String.t() | nil,
    language: String.t() | nil,
    content: String.t() | nil,
    additions: integer() | nil,
    deletions: integer() | nil,
    changes: integer() | nil,
    patch: String.t() | nil,
    pr_id: binary() | nil,
    pull_request: PullRequest.t() | Ecto.Association.NotLoaded.t() | nil,
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }
  
  @doc """
  Creates a changeset for a pull request file.
  """
  @spec changeset(PRFile.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:pr_id, :filename, :status, :language, :content, :additions, :deletions, :changes, :patch])
    |> validate_required([:pr_id, :filename])
    |> foreign_key_constraint(:pr_id)
  end
  
  @doc """
  Creates or updates a pull request file.
  """
  @spec upsert(map()) :: {:ok, PRFile.t()} | {:error, Ecto.Changeset.t()}
  def upsert(attrs) do
    case Repo.get_by(PRFile, pr_id: attrs.pr_id, filename: attrs.filename) do
      nil -> %PRFile{}
      file -> file
    end
    |> changeset(attrs)
    |> Repo.insert_or_update()
  end
  
  @doc """
  Creates a new pull request file.
  
  ## Parameters
    - attrs: Map of attributes to create with
    
  ## Returns
    - {:ok, file} on success
    - {:error, changeset} on failure
  """
  @spec create(map()) :: {:ok, PRFile.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %PRFile{}
    |> changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates an existing pull request file.
  
  ## Parameters
    - id: The file ID
    - attrs: Map of attributes to update
    
  ## Returns
    - {:ok, file} on success
    - {:error, changeset} on failure
  """
  @spec update(binary(), map()) :: {:ok, PRFile.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs) do
    PRFile
    |> Repo.get(id)
    |> changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Gets files for a pull request.
  """
  @spec get_files_for_pr(binary()) :: [PRFile.t()]
  def get_files_for_pr(pr_id) do
    PRFile
    |> where([f], f.pr_id == ^pr_id)
    |> order_by([f], f.filename)
    |> Repo.all()
  end
  
  @doc """
  Gets a file by ID.
  """
  @spec get_file(binary()) :: PRFile.t() | nil
  def get_file(id) do
    Repo.get(PRFile, id)
  end
  
  @doc """
  Gets a file by PR ID and filename.
  """
  @spec get_by_pr_and_filename(binary(), String.t()) :: PRFile.t() | nil
  def get_by_pr_and_filename(pr_id, filename) do
    Repo.get_by(PRFile, pr_id: pr_id, filename: filename)
  end
end 