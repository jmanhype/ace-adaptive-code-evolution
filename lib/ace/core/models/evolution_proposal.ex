defmodule Ace.Core.EvolutionProposal do
  @moduledoc """
  Represents a proposed code change that requires human review.
  """
  use Ace.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  import Ecto.Query
  alias Phoenix.PubSub
  alias Ace.Core.VersionControl
  
  schema "evolution_proposals" do
    field :dsl_name, :string
    field :proposed_code, :string
    field :status, :string, default: "pending_review"
    field :reviewer_id, :string
    field :review_comments, :string
    field :applied_at, :utc_datetime
    field :applied_version, :string
    
    belongs_to :optimization, Ace.Core.Optimization
    
    timestamps()
  end
  
  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :dsl_name, 
      :proposed_code, 
      :status, 
      :reviewer_id, 
      :review_comments, 
      :applied_at, 
      :applied_version,
      :optimization_id
    ])
    |> validate_required([:dsl_name, :proposed_code])
    |> validate_inclusion(:status, ["pending_review", "approved", "rejected", "applied"])
    |> foreign_key_constraint(:optimization_id)
  end
  
  @doc """
  Creates a new evolution proposal.
  
  ## Parameters
    
    - `attrs`: Map of attributes including:
      - `:dsl_name` - Module name the proposal applies to
      - `:proposed_code` - The new implementation
      - `:optimization_id` - Optional reference to the optimization
  
  ## Returns
  
    - `{:ok, proposal}`: The created proposal record
    - `{:error, changeset}`: If validation fails
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ace.Repo.insert()
    |> notify_on_new_proposal()
  end
  
  @doc """
  Approves a proposal.
  
  ## Parameters
    
    - `id`: ID of the proposal to approve
    - `reviewer_id`: ID of the reviewer
    - `comments`: Optional review comments
  
  ## Returns
  
    - `{:ok, proposal}`: The updated proposal record
    - `{:error, changeset}`: If validation fails
  """
  def approve(id, reviewer_id, comments \\ "") do
    from(p in __MODULE__, where: p.id == ^id)
    |> Ace.Repo.one()
    |> changeset(%{
      status: "approved", 
      reviewer_id: reviewer_id,
      review_comments: comments
    })
    |> Ace.Repo.update()
    |> notify_on_status_change()
  end
  
  @doc """
  Rejects a proposal.
  
  ## Parameters
    
    - `id`: ID of the proposal to reject
    - `reviewer_id`: ID of the reviewer
    - `comments`: Rejection reason/comments
  
  ## Returns
  
    - `{:ok, proposal}`: The updated proposal record
    - `{:error, changeset}`: If validation fails
  """
  def reject(id, reviewer_id, comments) do
    from(p in __MODULE__, where: p.id == ^id)
    |> Ace.Repo.one()
    |> changeset(%{
      status: "rejected", 
      reviewer_id: reviewer_id,
      review_comments: comments
    })
    |> Ace.Repo.update()
    |> notify_on_status_change()
  end
  
  @doc """
  Applies an approved proposal, generating a new code version.
  
  ## Parameters
    
    - `id`: ID of the proposal to apply
  
  ## Returns
  
    - `{:ok, version}`: Version string of the applied code
    - `{:error, reason}`: If applying the proposal fails
  """
  def apply_proposal(id) do
    proposal = from(p in __MODULE__, where: p.id == ^id) |> Ace.Repo.one()
    
    if proposal.status != "approved" do
      {:error, :not_approved}
    else
      # Apply the code
      with {:ok, version} <- VersionControl.save_new_version(
                              get_module_from_string(proposal.dsl_name), 
                              proposal.proposed_code
                            ),
           {:ok, updated_proposal} <- changeset(proposal, %{
                         status: "applied",
                         applied_at: DateTime.utc_now(),
                         applied_version: version
                       })
                       |> Ace.Repo.update() do
        # Broadcast event for real-time updates
        PubSub.broadcast(
          Ace.PubSub, 
          "evolution:updates", 
          {:proposal_applied, proposal.id}
        )
        
        # Record the successful evolution
        Ace.Core.EvolutionHistory.record_attempt(
          proposal.dsl_name, 
          true, 
          proposal.optimization_id
        )
        
        {:ok, version}
      end
    end
  end
  
  @doc """
  Lists pending proposals.
  """
  def list_pending() do
    from(p in __MODULE__, 
      where: p.status == "pending_review",
      order_by: [desc: p.inserted_at]
    )
    |> Ace.Repo.all()
  end
  
  @doc """
  Gets a proposal by ID.
  """
  def get_proposal(id) do
    Ace.Repo.get(__MODULE__, id)
  end
  
  @doc """
  Counts pending proposals.
  """
  def count_pending() do
    from(p in __MODULE__, 
      where: p.status == "pending_review",
      select: count(p.id)
    )
    |> Ace.Repo.one()
  end
  
  # Private helpers
  
  defp notify_on_new_proposal({:ok, proposal} = result) do
    PubSub.broadcast(
      Ace.PubSub,
      "evolution:proposals",
      {:new_proposal, proposal}
    )
    
    result
  end
  
  defp notify_on_new_proposal(error), do: error
  
  defp notify_on_status_change({:ok, proposal} = result) do
    PubSub.broadcast(
      Ace.PubSub,
      "evolution:proposals",
      {:proposal_status_changed, proposal}
    )
    
    result
  end
  
  defp notify_on_status_change(error), do: error
  
  defp get_module_from_string("Elixir." <> _ = module_string) do
    String.to_existing_atom(module_string)
  rescue
    ArgumentError -> String.to_atom(module_string)
  end
  
  defp get_module_from_string(module_string) do
    String.to_existing_atom("Elixir." <> module_string)
  rescue
    ArgumentError -> String.to_atom("Elixir." <> module_string)
  end
end