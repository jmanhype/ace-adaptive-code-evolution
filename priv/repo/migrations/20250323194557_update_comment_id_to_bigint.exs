defmodule Ace.Repo.Migrations.UpdateCommentIdToBigint do
  use Ecto.Migration

  def change do
    # Alter the column type of comment_id from integer to bigint in github_optimization_suggestions table
    alter table(:github_optimization_suggestions) do
      modify :comment_id, :bigint
    end
  end
end
