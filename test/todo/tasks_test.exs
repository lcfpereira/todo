defmodule Todo.TasksTest do
  use Todo.DataCase

  alias Todo.Tasks
  import Todo.TasksFixtures

  describe "tasks" do
    alias Todo.Tasks.Task

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

  describe "group_tasks/2" do
    # 2026-11-26 is a Thursday; its week starts Monday 2026-11-23.
    @today ~D[2026-11-26]

    defp t(id, attrs) do
      struct(
        Todo.Tasks.Task,
        Enum.into(attrs, %{
          id: id,
          title: "t#{id}",
          completed: false,
          due_date: nil,
          inserted_at: DateTime.add(~U[2026-11-01 00:00:00Z], id, :second)
        })
      )
    end

    test "undated tasks go to no_date" do
      assert %{no_date: [%{id: 1}], overdue: [], weeks: []} =
               Tasks.group_tasks([t(1, %{})], @today)
    end

    test "past incomplete tasks are overdue, past completed are not" do
      tasks = [
        t(1, %{due_date: ~D[2026-11-20]}),
        t(2, %{due_date: ~D[2026-11-20], completed: true})
      ]

      assert %{overdue: [%{id: 1}], weeks: [], no_date: []} = Tasks.group_tasks(tasks, @today)
    end

    test "earlier this week and incomplete is overdue; completed stays in its day" do
      tasks = [
        t(1, %{due_date: ~D[2026-11-24]}),
        t(2, %{due_date: ~D[2026-11-24], completed: true})
      ]

      assert %{
               overdue: [%{id: 1}],
               weeks: [%{days: [%{date: ~D[2026-11-24], tasks: [%{id: 2}]}]}]
             } =
               Tasks.group_tasks(tasks, @today)
    end

    test "completed task today stays on its day" do
      task = t(1, %{due_date: @today, completed: true})

      assert %{
               overdue: [],
               weeks: [%{start: ~D[2026-11-23], days: [%{date: @today, tasks: [^task]}]}]
             } =
               Tasks.group_tasks([task], @today)
    end

    test "weeks start on Monday" do
      tasks = [
        t(1, %{due_date: ~D[2026-11-29]}),
        t(2, %{due_date: ~D[2026-11-30]}),
        t(3, %{due_date: ~D[2026-12-06]}),
        t(4, %{due_date: ~D[2026-12-07]})
      ]

      assert %{weeks: weeks} = Tasks.group_tasks(tasks, @today)

      assert Enum.map(weeks, &{&1.start, Enum.map(&1.days, fn d -> d.date end)}) == [
               {~D[2026-11-23], [~D[2026-11-29]]},
               {~D[2026-11-30], [~D[2026-11-30], ~D[2026-12-06]]},
               {~D[2026-12-07], [~D[2026-12-07]]}
             ]
    end

    test "days are sorted and tasks ordered by inserted_at ascending" do
      tasks = [
        t(3, %{due_date: ~D[2026-11-27]}),
        t(1, %{due_date: ~D[2026-11-27]}),
        t(2, %{due_date: ~D[2026-11-26]}),
        t(5, %{}),
        t(4, %{})
      ]

      assert %{weeks: [%{days: days}], no_date: no_date} = Tasks.group_tasks(tasks, @today)

      assert [{~D[2026-11-26], [2]}, {~D[2026-11-27], [1, 3]}] ==
               Enum.map(days, &{&1.date, Enum.map(&1.tasks, fn x -> x.id end)})

      assert Enum.map(no_date, & &1.id) == [4, 5]
    end

    test "list_grouped_tasks/1 reads from the database" do
      task = task_fixture(%{completed: false, due_date: ~D[2026-11-26]})
      assert %{weeks: [%{days: [%{tasks: [found]}]}]} = Tasks.list_grouped_tasks(@today)
      assert found.id == task.id
    end
  end
end
