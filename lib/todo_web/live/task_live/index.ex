defmodule TodoWeb.TaskLive.Index do
  use TodoWeb, :live_view

  alias Todo.Tasks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Tasks
        <:actions>
          <.button variant="primary" navigate={~p"/tasks/new"}>
            <.icon name="hero-plus" /> New Task
          </.button>
        </:actions>
      </.header>

      <.table
        id="tasks"
        rows={@streams.tasks}
        row_click={fn {_id, task} -> JS.navigate(~p"/tasks/#{task}") end}
      >
        <:col :let={{_id, task}} label="Done">
          <input type="checkbox" checked={task.completed} phx-click="toggle" phx-value-id={task.id} />
        </:col>
        <:col :let={{_id, task}} label="Title">
          {task.title}
          <TodoWeb.LabelComponents.label_badges id={"task-#{task.id}-labels"} labels={task.labels} />
        </:col>
        <:col :let={{_id, task}} label="Completed">{task.completed}</:col>
        <:action :let={{_id, task}}>
          <div class="sr-only">
            <.link navigate={~p"/tasks/#{task}"}>Show</.link>
          </div>
          <.link navigate={~p"/tasks/#{task}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, task}}>
          <.link
            phx-click={JS.push("delete", value: %{id: task.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tasks")
     |> stream(:tasks, list_tasks())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, task} = Tasks.update_task(task, %{completed: !task.completed})
    {:noreply, stream_insert(socket, :tasks, task)}
  end

  defp list_tasks() do
    Tasks.list_tasks()
  end
end
