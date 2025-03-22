defmodule Ace.Repo.Migrations.CreateEvolutionTables do
  use Ecto.Migration
  import Ecto.Query

  def change do
    # Create evolution_proposals table if it doesn't exist
    unless table_exists?(:evolution_proposals) do
      create table(:evolution_proposals, primary_key: false) do
        add :id, :binary_id, primary_key: true
        add :dsl_name, :string, null: false
        add :proposed_code, :text, null: false
        add :status, :string, default: "pending_review", null: false
        add :reviewer_id, :string
        add :review_comments, :text
        add :applied_at, :utc_datetime
        add :applied_version, :string
        add :optimization_id, references(:optimizations, type: :binary_id, on_delete: :nilify_all)
        
        timestamps()
      end

      create index(:evolution_proposals, [:optimization_id])
      create index(:evolution_proposals, [:status])
      create index(:evolution_proposals, [:dsl_name])
    end

    # Create evolution_history table if it doesn't exist
    unless table_exists?(:evolution_history) do
      create table(:evolution_history, primary_key: false) do
        add :id, :binary_id, primary_key: true
        add :dsl_name, :string, null: false
        add :date, :utc_datetime, null: false
        add :was_successful, :boolean, default: false
        add :metrics, :map, default: %{}
        add :optimization_id, references(:optimizations, type: :binary_id, on_delete: :nilify_all)
        
        timestamps()
      end
      
      create index(:evolution_history, [:dsl_name])
      create index(:evolution_history, [:optimization_id])
      create index(:evolution_history, [:date])
    end
  end
  
  defp table_exists?(table) do
    query = "SELECT to_regclass($1)"
    result = Ecto.Adapters.SQL.query!(Ace.Repo, query, ["public.#{table}"])
    result.rows |> List.first() |> List.first() != nil
  end
end
