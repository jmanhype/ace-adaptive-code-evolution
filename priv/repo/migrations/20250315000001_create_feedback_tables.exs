defmodule Ace.Repo.Migrations.CreateFeedbackTables do
  use Ecto.Migration

  def change do
    create table(:feedback, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :score, :integer, null: false
      add :comment, :text
      add :source, :string, null: false
      add :user_id, :string
      add :feature_id, :string
      add :optimization_id, references(:optimizations, type: :uuid, on_delete: :nilify_all)
      
      timestamps()
    end
    
    create index(:feedback, [:source])
    create index(:feedback, [:optimization_id])
    create index(:feedback, [:feature_id])
    
    create table(:evolution_history, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :dsl_name, :string, null: false
      add :date, :utc_datetime, null: false
      add :was_successful, :boolean, default: false
      add :optimization_id, references(:optimizations, type: :uuid, on_delete: :nilify_all)
      add :metrics, :map
      
      timestamps()
    end
    
    create index(:evolution_history, [:dsl_name])
    create index(:evolution_history, [:date])
    create index(:evolution_history, [:was_successful])
    
    create table(:evolution_proposals, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :dsl_name, :string, null: false
      add :proposed_code, :text, null: false
      add :status, :string, default: "pending_review"
      add :reviewer_id, :string
      add :review_comments, :text
      add :applied_at, :utc_datetime
      add :applied_version, :string
      add :optimization_id, references(:optimizations, type: :uuid, on_delete: :nilify_all)
      
      timestamps()
    end
    
    create index(:evolution_proposals, [:dsl_name])
    create index(:evolution_proposals, [:status])
  end
end