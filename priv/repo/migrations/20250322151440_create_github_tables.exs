defmodule Ace.Repo.Migrations.CreateGithubTables do
  use Ecto.Migration

  def change do
    # Create GitHub PR table
    create table(:github_pull_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pr_id, :bigint, null: false
      add :number, :integer, null: false
      add :title, :string
      add :html_url, :string, null: false
      add :diff_url, :string
      add :state, :string, default: "open"
      add :repo_name, :string, null: false
      add :repo_url, :string
      add :head_sha, :string
      add :base_sha, :string
      add :status, :string, default: "pending" # pending, processing, optimized, commented, error
      add :last_processed_at, :utc_datetime_usec
      
      timestamps()
    end
    
    # Create unique constraint on PR number and repo name
    create unique_index(:github_pull_requests, [:pr_id, :repo_name], name: :github_pr_unique_index)
    create index(:github_pull_requests, [:status])
    
    # Table for PR file changes
    create table(:github_pr_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pr_id, references(:github_pull_requests, type: :binary_id, on_delete: :delete_all), null: false
      add :filename, :string, null: false
      add :status, :string
      add :additions, :integer, default: 0
      add :deletions, :integer, default: 0
      add :changes, :integer, default: 0
      add :patch, :text
      add :content, :text
      add :language, :string
      
      timestamps()
    end
    
    create index(:github_pr_files, [:pr_id])
    create unique_index(:github_pr_files, [:pr_id, :filename], name: :github_pr_file_unique_index)
    
    # Table for optimization suggestions
    create table(:github_optimization_suggestions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pr_id, references(:github_pull_requests, type: :binary_id, on_delete: :delete_all), null: false
      add :file_id, references(:github_pr_files, type: :binary_id, on_delete: :delete_all), null: false
      add :opportunity_type, :string, null: false
      add :location, :string, null: false
      add :description, :text, null: false
      add :severity, :string, default: "medium"
      add :original_code, :text, null: false
      add :optimized_code, :text, null: false
      add :explanation, :text
      add :status, :string, default: "pending" # pending, submitted, rejected, accepted
      add :comment_id, :integer # GitHub comment ID if posted
      add :metrics, :map, default: %{}
      
      timestamps()
    end
    
    create index(:github_optimization_suggestions, [:pr_id])
    create index(:github_optimization_suggestions, [:file_id])
  end
end
