defmodule Ace.Repo.Migrations.AddUserToGithubPullRequests do
  use Ecto.Migration

  def change do
    alter table(:github_pull_requests) do
      add :user, :string
    end
  end
end 