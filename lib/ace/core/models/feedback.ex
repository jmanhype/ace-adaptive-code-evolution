defmodule Ace.Core.Feedback do
  @moduledoc """
  Schema for user feedback on optimizations or features.
  This is used to collect NPS and comments to guide future evolution.
  """
  use Ace.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  
  schema "feedback" do
    field :score, :integer
    field :comment, :string
    field :source, :string
    field :user_id, :string
    field :feature_id, :string
    
    belongs_to :optimization, Ace.Core.Optimization
    
    timestamps()
  end
  
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:score, :comment, :source, :user_id, :feature_id, :optimization_id])
    |> validate_required([:score, :source])
    |> validate_inclusion(:score, 0..10)
    |> validate_length(:comment, max: 1000)
    |> foreign_key_constraint(:optimization_id)
  end
  
  @doc """
  Creates a new feedback entry.
  
  ## Parameters
    
    - `attrs`: Map of attributes including:
      - `:score` - Integer 0-10 representing NPS score
      - `:comment` - Optional feedback comment
      - `:source` - Source of the feedback (e.g., "dashboard", "api", "cli")
      - `:user_id` - Optional ID of the user providing feedback
      - `:feature_id` - Optional ID of the feature being rated
      - `:optimization_id` - Optional ID of the optimization being rated
  
  ## Returns
  
    - `{:ok, feedback}`: The created feedback record
    - `{:error, changeset}`: If validation fails
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ace.Repo.insert()
  end
  
  @doc """
  Creates a new feedback entry without possibility of error.
  
  Raises an exception if validation fails.
  """
  def create!(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ace.Repo.insert!()
  end
  
  @doc """
  Gets average NPS score for a given source or feature.
  
  ## Parameters
    
    - `opts`: Keyword list of filters:
      - `:source` - Filter by feedback source
      - `:feature_id` - Filter by feature ID
      - `:optimization_id` - Filter by optimization ID
      - `:since` - Only include feedback since this DateTime
  
  ## Returns
  
    - Average score or nil if no feedback found
  """
  def average_score(opts \\ []) do
    __MODULE__
    |> apply_filters(opts)
    |> Ace.Repo.aggregate(:avg, :score)
  end
  
  @doc """
  Gets NPS distribution for a given source or feature.
  
  Returns a map with keys `:detractors` (0-6), `:passive` (7-8), and `:promoters` (9-10)
  containing the count and percentage of each category.
  """
  def nps_distribution(opts \\ []) do
    base_query = apply_filters(__MODULE__, opts)
    
    total = Ace.Repo.aggregate(base_query, :count, :id)
    
    if total > 0 do
      detractors = Ace.Repo.aggregate(base_query |> where([f], f.score <= 6), :count, :id)
      passives = Ace.Repo.aggregate(base_query |> where([f], f.score in [7, 8]), :count, :id)
      promoters = Ace.Repo.aggregate(base_query |> where([f], f.score >= 9), :count, :id)
      
      %{
        detractors: %{
          count: detractors,
          percentage: Float.round(detractors / total * 100, 1)
        },
        passive: %{
          count: passives,
          percentage: Float.round(passives / total * 100, 1)
        },
        promoters: %{
          count: promoters,
          percentage: Float.round(promoters / total * 100, 1)
        },
        nps_score: Float.round((promoters / total) * 100 - (detractors / total) * 100, 1),
        total: total
      }
    else
      %{
        detractors: %{count: 0, percentage: 0.0},
        passive: %{count: 0, percentage: 0.0},
        promoters: %{count: 0, percentage: 0.0},
        nps_score: 0.0,
        total: 0
      }
    end
  end
  
  @doc """
  Lists recent feedback with optional filtering and pagination.
  """
  def list(opts \\ []) do
    __MODULE__
    |> apply_filters(opts)
    |> maybe_preload(opts[:preload])
    |> order_by([f], desc: f.inserted_at)
    |> maybe_limit(opts[:limit])
    |> Ace.Repo.all()
  end
  
  # Private helpers for query building
  
  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:source, source}, query ->
        query |> where([f], f.source == ^source)
      
      {:feature_id, feature_id}, query ->
        query |> where([f], f.feature_id == ^feature_id)
      
      {:optimization_id, optimization_id}, query ->
        query |> where([f], f.optimization_id == ^optimization_id)
      
      {:since, since}, query ->
        query |> where([f], f.inserted_at >= ^since)
      
      _, query ->
        query
    end)
  end
  
  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: query |> preload(^preloads)
  
  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: query |> limit(^limit)
end