defmodule TimeQuantifier.GoalManagement.Goal do
  use Ecto.Schema
  import Ecto.Changeset


  schema "goals" do
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [:reason])
    |> validate_required([:reason])
  end
end
