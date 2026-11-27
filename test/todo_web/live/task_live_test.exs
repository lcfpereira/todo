defmodule TodoWeb.TaskLiveTest do
  use TodoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todo.TasksFixtures

  @create_attrs %{title: "some title", completed: true}
  @update_attrs %{title: "some updated title", completed: false}
  @invalid_attrs %{title: nil, completed: false}
  defp create_task(_) do
    task = task_fixture()

    %{task: task}
  end

  describe "Index" do
    setup [:create_task]

    test "lists all tasks", %{conn: conn, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks")

      assert html =~ "Listing Tasks"
      assert html =~ task.title
    end

    test "saves new task", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Task")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/new")

      assert render(form_live) =~ "New Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#task-form", task: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Task created successfully"
      assert html =~ "some title"
    end

    test "updates task in listing", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#tasks-#{task.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/#{task}/edit")

      assert render(form_live) =~ "Edit Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#task-form", task: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      html = render(index_live)
      assert html =~ "Task updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes task in listing", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/tasks")

      assert index_live |> element("#tasks-#{task.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tasks-#{task.id}")
    end
  end

  describe "Show" do
    setup [:create_task]

    test "displays task", %{conn: conn, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.title
    end

    test "updates task and returns to show", %{conn: conn, task: task} do
      {:ok, show_live, _html} = live(conn, ~p"/tasks/#{task}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/tasks/#{task}/edit?return_to=show")

      assert render(form_live) =~ "Edit Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#task-form", task: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks/#{task}")

      html = render(show_live)
      assert html =~ "Task updated successfully"
      assert html =~ "some updated title"
    end
  end

  describe "Labels" do
    test "creates a task with new and existing labels via the form", %{conn: conn} do
      {:ok, existing} = Todo.Labels.create_label(%{name: "Work"})
      {:ok, form_live, _} = live(conn, ~p"/tasks/new")

      assert has_element?(form_live, "#label-picker")
      assert has_element?(form_live, "#task_label_#{existing.id}")

      form_live
      |> form("#task-form",
        task: %{title: "with labels", label_ids: [existing.id], new_labels: "Home, work"}
      )
      |> render_submit()

      {:ok, index_live, _} = live(conn, ~p"/tasks")
      [task] = Todo.Tasks.list_tasks()
      assert Enum.sort(Enum.map(task.labels, & &1.name)) == ["Home", "Work"]
      assert has_element?(index_live, "#task-#{task.id}-labels")

      for label <- task.labels,
          do: assert(has_element?(index_live, "#task-#{task.id}-labels-label-#{label.id}"))
    end

    test "shows an error for an overlong new label", %{conn: conn} do
      {:ok, form_live, _} = live(conn, ~p"/tasks/new")

      html =
        form_live
        |> form("#task-form", task: %{title: "x", new_labels: String.duplicate("a", 31)})
        |> render_submit()

      assert html =~ "should be at most 30"
    end

    test "edit form preselects labels and show page renders badges", %{conn: conn} do
      {:ok, task} = Todo.Tasks.create_task(%{"title" => "t", "new_labels" => "Alpha"})
      [label] = task.labels

      {:ok, edit_live, _} = live(conn, ~p"/tasks/#{task}/edit")
      assert has_element?(edit_live, "#task_label_#{label.id}[checked]")

      {:ok, show_live, _} = live(conn, ~p"/tasks/#{task}")
      assert has_element?(show_live, "#task-labels-label-#{label.id}")
    end

    test "tasks without labels render no badge container", %{conn: conn} do
      task = task_fixture()
      {:ok, index_live, _} = live(conn, ~p"/tasks")
      refute has_element?(index_live, "#task-#{task.id}-labels")
    end
  end
end
