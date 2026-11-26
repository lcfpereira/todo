defmodule Todo.LabelsTest do
  use Todo.DataCase

  alias Todo.{Labels, Repo, Tasks}
  alias Todo.Labels.Label
  import Todo.TasksFixtures

  test "name is trimmed, required and max 30 chars" do
    assert {:ok, %Label{name: "work"}} = Labels.create_label(%{name: "  work  "})
    assert %{name: ["can't be blank"]} = errors_on(Labels.change_label(%Label{}, %{name: "  "}))

    assert %{name: [_]} =
             errors_on(Labels.change_label(%Label{}, %{name: String.duplicate("a", 31)}))
  end

  test "names are unique case-insensitively" do
    {:ok, _} = Labels.create_label(%{name: "Home"})
    assert {:error, cs} = Labels.create_label(%{name: "hOME"})
    assert %{name: ["has already been taken"]} = errors_on(cs)
  end

  test "get_or_create_label/1 reuses existing labels regardless of case" do
    {:ok, a} = Labels.get_or_create_label("Errands")
    {:ok, b} = Labels.get_or_create_label(" errands ")
    assert a.id == b.id
    assert length(Labels.list_labels()) == 1
  end

  test "resolve_labels/1 combines ids and new comma-separated names" do
    {:ok, existing} = Labels.create_label(%{name: "Work"})

    assert {:ok, labels} =
             Labels.resolve_labels(%{
               "label_ids" => ["", to_string(existing.id)],
               "new_labels" => "work, Home, , home"
             })

    assert labels |> Enum.map(& &1.name) |> Enum.sort() == ["Home", "Work"]
  end

  test "tasks can be created and updated with labels, and preload them" do
    {:ok, task} = Tasks.create_task(%{"title" => "t", "new_labels" => "a, b"})
    assert Enum.map(task.labels, & &1.name) |> Enum.sort() == ["a", "b"]

    [listed] = Tasks.list_tasks()
    assert length(listed.labels) == 2
    assert length(Tasks.get_task!(task.id).labels) == 2

    keep = Enum.find(task.labels, &(&1.name == "a"))

    {:ok, updated} =
      Tasks.update_task(task, %{"label_ids" => [to_string(keep.id)], "new_labels" => ""})

    assert [%{name: "a"}] = updated.labels

    # updates without label params leave labels untouched
    {:ok, updated} = Tasks.update_task(updated, %{completed: true})
    assert [%{name: "a"}] = updated.labels
  end

  test "an invalid task does not leave new labels behind" do
    assert {:error, _} = Tasks.create_task(%{"title" => "", "new_labels" => "ghost"})
    assert Labels.list_labels() == []
  end

  test "an overlong new label is reported as an error on the task" do
    assert {:error, cs} =
             Tasks.create_task(%{"title" => "t", "new_labels" => String.duplicate("x", 31)})

    assert %{new_labels: [_]} = errors_on(cs)
    assert Tasks.list_tasks() == []
  end

  test "deleting a label detaches it but keeps the task" do
    {:ok, task} = Tasks.create_task(%{"title" => "t", "new_labels" => "gone"})
    [label] = task.labels
    {:ok, _} = Labels.delete_label(label)
    assert Tasks.get_task!(task.id).labels == []
  end

  test "deleting a task removes join rows but keeps the label" do
    {:ok, task} = Tasks.create_task(%{"title" => "t", "new_labels" => "stay"})
    {:ok, _} = Tasks.delete_task(task)
    assert [%Label{name: "stay"}] = Labels.list_labels()
    assert Repo.aggregate("task_labels", :count) == 0
    _ = task_fixture()
  end
end
