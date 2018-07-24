defmodule TimeQuantifier.GoalManagementTest do
  use TimeQuantifier.DataCase

  alias TimeQuantifier.GoalManagement

  describe "goals" do
    alias TimeQuantifier.GoalManagement.Goal

    @valid_attrs %{reason: "some reason"}
    @update_attrs %{reason: "some updated reason"}
    @invalid_attrs %{reason: nil}

    def goal_fixture(attrs \\ %{}) do
      {:ok, goal} =
        attrs
        |> Enum.into(@valid_attrs)
        |> GoalManagement.create_goal()

      goal
    end

    test "list_goals/0 returns all goals" do
      goal = goal_fixture()
      assert GoalManagement.list_goals() == [goal]
    end

    test "get_goal!/1 returns the goal with given id" do
      goal = goal_fixture()
      assert GoalManagement.get_goal!(goal.id) == goal
    end

    test "create_goal/1 with valid data creates a goal" do
      assert {:ok, %Goal{} = goal} = GoalManagement.create_goal(@valid_attrs)
      assert goal.reason == "some reason"
    end

    test "create_goal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GoalManagement.create_goal(@invalid_attrs)
    end

    test "update_goal/2 with valid data updates the goal" do
      goal = goal_fixture()
      assert {:ok, goal} = GoalManagement.update_goal(goal, @update_attrs)
      assert %Goal{} = goal
      assert goal.reason == "some updated reason"
    end

    test "update_goal/2 with invalid data returns error changeset" do
      goal = goal_fixture()
      assert {:error, %Ecto.Changeset{}} = GoalManagement.update_goal(goal, @invalid_attrs)
      assert goal == GoalManagement.get_goal!(goal.id)
    end

    test "delete_goal/1 deletes the goal" do
      goal = goal_fixture()
      assert {:ok, %Goal{}} = GoalManagement.delete_goal(goal)
      assert_raise Ecto.NoResultsError, fn -> GoalManagement.get_goal!(goal.id) end
    end

    test "change_goal/1 returns a goal changeset" do
      goal = goal_fixture()
      assert %Ecto.Changeset{} = GoalManagement.change_goal(goal)
    end
  end
end
