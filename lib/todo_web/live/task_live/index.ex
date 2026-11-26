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

      <%!-- One stream item per section (overdue, each week, no-date). Rows are nested inside. --%>
      <div id="task-sections" phx-update="stream" class="mt-6 space-y-8">
        <div id="tasks-empty" class="hidden only:block text-base-content/60">No tasks yet</div>
        <section :for={{dom_id, section} <- @streams.sections} id={dom_id}>
          <h2 class="text-lg font-semibold">{section.title}</h2>

          <%= if section.kind == :week do %>
            <div :for={day <- section.days} id={"#{dom_id}-day-#{day.date}"} class="mt-3">
              <h3 class="text-sm font-medium text-base-content/70">{day_label(day.date)}</h3>
              <.task_rows tasks={day.tasks} />
            </div>
          <% else %>
            <.task_rows tasks={section.tasks} />
          <% end %>
        </section>
      </div>
    </Layouts.app>
    """
  end

  attr :tasks, :list, required: true

  defp task_rows(assigns) do
    ~H"""
    <ul class="divide-y divide-base-300">
      <li :for={task <- @tasks} id={"tasks-#{task.id}"} class="flex items-center gap-3 py-2">
        <input
          type="checkbox"
          id={"toggle-#{task.id}"}
          checked={task.completed}
          phx-click="toggle"
          phx-value-id={task.id}
        />
        <.link
          navigate={~p"/tasks/#{task}"}
          class={["flex-1", task.completed && "line-through text-base-content/50"]}
        >
          {task.title}
        </.link>
        <.link navigate={~p"/tasks/#{task}/edit"}>Edit</.link>
        <.link
          phx-click={JS.push("delete", value: %{id: task.id})}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </li>
    </ul>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Tasks")
     |> load_sections()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    {:noreply, load_sections(socket)}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _task} = Tasks.update_task(task, %{completed: !task.completed})
    {:noreply, load_sections(socket)}
  end

  defp load_sections(socket) do
    stream(socket, :sections, build_sections(Tasks.list_grouped_tasks()),
      reset: true,
      dom_id: & &1.id
    )
  end

  defp build_sections(%{overdue: overdue, weeks: weeks, no_date: no_date}) do
    overdue_section =
      if overdue != [],
        do: [%{id: "overdue", kind: :overdue, title: "Overdue", tasks: overdue}],
        else: []

    no_date_section =
      if no_date != [],
        do: [%{id: "no-date", kind: :no_date, title: "No date", tasks: no_date}],
        else: []

    week_sections =
      Enum.map(weeks, fn week ->
        %{
          id: "week-#{week.start}",
          kind: :week,
          title: "Week of #{Calendar.strftime(week.start, "%b %-d")}",
          days: week.days
        }
      end)

    overdue_section ++ week_sections ++ no_date_section
  end

  defp day_label(date), do: Calendar.strftime(date, "%A, %b %-d")
end
