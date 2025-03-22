defmodule Ace.Core.EvolutionHistory do
  @moduledoc """
  Stores the history of evolution attempts for a particular module/DSL.
  """
  use Ace.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  import Ecto.Query
  
  schema "evolution_history" do
    field :dsl_name, :string
    field :date, :utc_datetime
    field :was_successful, :boolean, default: false
    field :metrics, :map
    
    belongs_to :optimization, Ace.Core.Optimization
    
    timestamps()
  end
  
  def changeset(history, attrs) do
    history
    |> cast(attrs, [:dsl_name, :date, :was_successful, :metrics, :optimization_id])
    |> validate_required([:dsl_name, :date])
    |> foreign_key_constraint(:optimization_id)
  end
  
  @doc """
  Records a new evolution attempt in the history.
  """
  def record_attempt(dsl_name, was_successful, optimization_id \\ nil, metrics \\ %{}) do
    dsl_name_str = case dsl_name do
      name when is_atom(name) -> Atom.to_string(name)
      name when is_binary(name) -> name
      _ -> raise ArgumentError, "dsl_name must be an atom or string"
    end
    
    %__MODULE__{}
    |> changeset(%{
      dsl_name: dsl_name_str,
      date: DateTime.utc_now(),
      was_successful: was_successful,
      optimization_id: optimization_id,
      metrics: metrics
    })
    |> Ace.Repo.insert()
  end
  
  @doc """
  Creates a new evolution history entry.
  
  ## Parameters
    
    - `attrs`: Map of attributes including:
      - `:dsl_name` - Name of the DSL/module
      - `:date` - UTC datetime of the evolution attempt
      - `:was_successful` - Whether the evolution was successful
      - `:metrics` - Optional map of metrics related to the evolution
      - `:optimization_id` - Optional ID of the related optimization
  
  ## Returns
  
    The created evolution history record. Raises an exception if validation fails.
  """
  def create!(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ace.Repo.insert!()
  end
  
  @doc """
  Creates a new evolution history entry.
  
  ## Parameters
    
    - `attrs`: Map of attributes including:
      - `:dsl_name` - Name of the DSL/module
      - `:date` - UTC datetime of the evolution attempt
      - `:was_successful` - Whether the evolution was successful
      - `:metrics` - Optional map of metrics related to the evolution
      - `:optimization_id` - Optional ID of the related optimization
  
  ## Returns
  
    - `{:ok, history}`: The created evolution history record
    - `{:error, changeset}`: If validation fails
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ace.Repo.insert()
  end
  
  @doc """
  Gets evolution context for a specific DSL/module.
  
  Returns a list of history entries, ordered by date descending (most recent first).
  """
  def get_evolution_context(dsl_name) when is_atom(dsl_name) do
    get_evolution_context(Atom.to_string(dsl_name))
  end
  
  def get_evolution_context(dsl_name) when is_binary(dsl_name) do
    __MODULE__
    |> where([h], h.dsl_name == ^dsl_name)
    |> preload(:optimization)
    |> order_by(desc: :date)
    |> Ace.Repo.all()
  end
  
  @doc """
  Gets success rate for evolution attempts.
  """
  def success_rate(dsl_name \\ nil) do
    base_query = if dsl_name do
      dsl_name_str = if is_atom(dsl_name), do: Atom.to_string(dsl_name), else: dsl_name
      __MODULE__ |> where([h], h.dsl_name == ^dsl_name_str)
    else
      __MODULE__
    end
    
    total = Ace.Repo.aggregate(base_query, :count, :id)
    
    if total > 0 do
      successful = Ace.Repo.aggregate(
        base_query |> where([h], h.was_successful == true), 
        :count, 
        :id
      )
      
      %{
        total_attempts: total,
        successful_attempts: successful,
        rate: Float.round(successful / total * 100, 1)
      }
    else
      %{
        total_attempts: 0,
        successful_attempts: 0,
        rate: 0.0
      }
    end
  end
end