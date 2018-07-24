defmodule TimeQuantifier.Repo.Migrations.CreateGoals do
  use Ecto.Migration

  def change do
    create table(:goals) do
      add(:reason, :string)
      add(:yearly_time_goal, :int)
      add(:current_time_accrued, :int)

      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end
  end
end
