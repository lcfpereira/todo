defmodule Todo.TasksTest do
  use Todo.DataCase

  alias Todo.Tasks

  describe "tasks" do
    alias Todo.Tasks.Task

    import Todo.TasksFixtures

    @invalid_attrs %{title: nil, completed: nil}

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Tasks.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{title: "some title", completed: true}

      assert {:ok, %Task{} = task} = Tasks.create_task(valid_attrs)
      assert task.title == "some title"
      assert task.completed == true
    end

    test "create_task/1 with a due date stores it" do
      assert {:ok, %Task{} = task} =
               Tasks.create_task(%{title: "dated", due_date: ~D[2026-12-01]})

      assert task.due_date == ~D[2026-12-01]
      assert Tasks.get_task!(task.id).due_date == ~D[2026-12-01]
    end

    test "create_task/1 without a due date leaves it nil" do
      assert {:ok, %Task{due_date: nil}} = Tasks.create_task(%{title: "undated"})
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(@invalid_attrs)
    end

    test "update_task/2 with valid data updates the task" do
      task = task_fixture()
      update_attrs = %{title: "some updated title", completed: false}

      assert {:ok, %Task{} = task} = Tasks.update_task(task, update_attrs)
      assert task.title == "some updated title"
      assert task.completed == false
    end

    test "update_task/2 sets and clears the due date" do
      task = task_fixture()

      assert {:ok, %Task{due_date: ~D[2026-12-24]} = task} =
               Tasks.update_task(task, %{due_date: ~D[2026-12-24]})

      assert {:ok, %Task{due_date: nil}} = Tasks.update_task(task, %{due_date: nil})
    end

    test "update_task/2 with an invalid due date returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, %{due_date: "not a date"})
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, @invalid_attrs)
      assert task == Tasks.get_task!(task.id)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = Tasks.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Tasks.change_task(task)
    end
  end
end
