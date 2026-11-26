defmodule TodoWeb.TaskLiveTest do
  use TodoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todo.TasksFixtures

  @create_attrs %{title: "some title", completed: true, due_date: "2026-12-01"}
  @update_attrs %{title: "some updated title", completed: false, due_date: "2026-12-24"}
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
      task = Todo.Repo.get_by!(Todo.Tasks.Task, due_date: ~D[2026-12-01])
      assert has_element?(index_live, "#tasks-#{task.id}-due-date", "2026-12-01")
    end

    test "saves new task without a due date", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/tasks/new")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#task-form", task: %{title: "undated task", due_date: ""})
               |> render_submit()
               |> follow_redirect(conn, ~p"/tasks")

      task = Todo.Repo.get_by!(Todo.Tasks.Task, title: "undated task")
      assert task.due_date == nil
      assert has_element?(index_live, "#tasks-#{task.id}-due-date", "No date")
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
      assert has_element?(index_live, "#tasks-#{task.id}-due-date", "2026-12-24")
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
      {:ok, show_live, html} = live(conn, ~p"/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.title
      assert has_element?(show_live, "#task-due-date", "No date")
    end

    test "displays due date", %{conn: conn} do
      task = task_fixture(%{due_date: ~D[2026-12-01]})
      {:ok, show_live, _html} = live(conn, ~p"/tasks/#{task}")
      assert has_element?(show_live, "#task-due-date", "2026-12-01")
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
      assert has_element?(show_live, "#task-due-date", "2026-12-24")
    end
  end
end
