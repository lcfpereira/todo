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

    test "groups tasks into sections", %{conn: conn, task: undated} do
      today = Date.utc_today()
      overdue = task_fixture(%{title: "late", completed: false, due_date: Date.add(today, -3)})
      done = task_fixture(%{title: "done", completed: true, due_date: today})
      week = Date.beginning_of_week(today, :monday)

      {:ok, view, _html} = live(conn, ~p"/tasks")

      assert has_element?(view, "#overdue #tasks-#{overdue.id}")
      assert has_element?(view, "#no-date #tasks-#{undated.id}")
      assert has_element?(view, "#week-#{week} #week-#{week}-day-#{today} #tasks-#{done.id}")
      assert has_element?(view, "#tasks-#{done.id} a.line-through")
      refute has_element?(view, "#overdue #tasks-#{done.id}")
    end

    test "toggling moves a task between sections", %{conn: conn} do
      today = Date.utc_today()
      late = task_fixture(%{completed: false, due_date: Date.add(today, -2)})
      {:ok, view, _html} = live(conn, ~p"/tasks")
      assert has_element?(view, "#overdue #tasks-#{late.id}")

      view |> element("#toggle-#{late.id}") |> render_click()
      refute has_element?(view, "#overdue")
      assert has_element?(view, "#tasks-#{late.id} a.line-through")
    end

    test "shows empty state without tasks", %{conn: conn, task: task} do
      Todo.Tasks.delete_task(task)
      {:ok, view, _html} = live(conn, ~p"/tasks")
      assert has_element?(view, "#tasks-empty")
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
end
