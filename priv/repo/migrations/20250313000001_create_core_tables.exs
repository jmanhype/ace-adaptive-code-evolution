defmodule Ace.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    # Create project table for multi-file analyses
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :base_path, :string, null: false
      add :description, :text
      add :settings, :map, default: %{}
      
      timestamps()
    end
    
    create table(:analyses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_path, :string, null: false
      add :language, :string, null: false
      add :content, :text, null: false
      add :focus_areas, {:array, :string}, default: ["performance", "maintainability"]
      add :severity_threshold, :string, default: "medium"
      add :completed_at, :utc_datetime_usec
      add :is_multi_file, :boolean, default: false
      add :project_id, references(:projects, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create table(:opportunities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :location, :string, null: false
      add :type, :string, null: false
      add :description, :text, null: false
      add :severity, :string, null: false
      add :rationale, :text
      add :suggested_change, :text
      add :analysis_id, references(:analyses, type: :binary_id, on_delete: :delete_all), null: false
      add :cross_file_references, {:array, :map}, default: []
      add :scope, :string, default: "single_file" # Can be single_file or cross_file

      timestamps()
    end

    create table(:optimizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :strategy, :string, null: false
      add :original_code, :text, null: false
      add :optimized_code, :text, null: false
      add :explanation, :text
      add :status, :string, default: "pending"
      add :opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:evaluations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :metrics, :map, null: false
      add :success, :boolean, null: false
      add :report, :text
      add :optimization_id, references(:optimizations, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:experiments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :setup_data, :map
      add :results, :map
      add :status, :string, default: "pending", null: false
      add :experiment_path, :string
      add :evaluation_id, references(:evaluations, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    # Create analysis relationships table
    create table(:analysis_relationships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_analysis_id, references(:analyses, type: :binary_id, on_delete: :delete_all), null: false
      add :target_analysis_id, references(:analyses, type: :binary_id, on_delete: :delete_all), null: false
      add :relationship_type, :string, null: false # imports, extends, implements, etc.
      add :details, :map, default: %{}
      
      timestamps()
    end

    # Create indexes
    create index(:opportunities, [:analysis_id])
    create index(:optimizations, [:opportunity_id])
    create index(:evaluations, [:optimization_id])
    create index(:experiments, [:evaluation_id])
    create index(:analyses, [:project_id])
    create index(:analysis_relationships, [:source_analysis_id])
    create index(:analysis_relationships, [:target_analysis_id])
    
    # Create unique constraint on source and target analysis for relationships
    create unique_index(:analysis_relationships, [:source_analysis_id, :target_analysis_id, :relationship_type], name: :analysis_relationship_unique_index)
  end
end