defmodule TodoWeb.TaskLive.Form do
  use TodoWeb, :live_view

  alias Todo.Tasks
  alias Todo.Tasks.Task

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage task records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="task-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:completed]} type="checkbox" label="Completed" />
        <%!-- Raw checkboxes on purpose: <.input type="checkbox"> only supports a single boolean value. --%>
        <fieldset id="label-picker" class="mb-2">
          <legend class="label mb-1">Labels</legend>
          <input type="hidden" name="task[label_ids][]" value="" />
          <label :for={label <- @labels} class="mr-4 inline-flex items-center gap-1">
            <input
              type="checkbox"
              id={"task_label_#{label.id}"}
              name="task[label_ids][]"
              value={label.id}
              checked={label.id in @selected_label_ids}
              class="checkbox checkbox-sm"
            />
            {label.name}
          </label>
        </fieldset>
        <.input
          field={@form[:new_labels]}
          type="text"
          label="New labels (comma-separated)"
          value={@new_labels}
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Task</.button>
          <.button navigate={return_path(@return_to, @task)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    task = Tasks.get_task!(id)

    socket
    |> assign(:page_title, "Edit Task")
    |> assign(:task, task)
    |> assign_labels(task)
    |> assign(:form, to_form(Tasks.change_task(task)))
  end

  defp apply_action(socket, :new, _params) do
    task = %Task{labels: []}

    socket
    |> assign(:page_title, "New Task")
    |> assign(:task, task)
    |> assign_labels(task)
    |> assign(:form, to_form(Tasks.change_task(task)))
  end

  defp assign_labels(socket, task) do
    socket
    |> assign(:labels, Todo.Labels.list_labels())
    |> assign(:selected_label_ids, Enum.map(Map.get(task, :labels, []), & &1.id))
    |> assign(:new_labels, "")
  end

  # Keep the label picker in sync with what the user has typed/checked so far.
  defp track_labels(socket, params) do
    ids = params |> Map.get("label_ids", []) |> Todo.Labels.parse_ids()

    socket
    |> assign(:selected_label_ids, ids)
    |> assign(:new_labels, Map.get(params, "new_labels", ""))
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset = Tasks.change_task(socket.assigns.task, task_params)

    {:noreply,
     socket |> track_labels(task_params) |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    socket = track_labels(socket, task_params)
    save_task(socket, socket.assigns.live_action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    case Tasks.update_task(socket.assigns.task, task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, task))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_task(socket, :new, task_params) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, task))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _task), do: ~p"/tasks"
  defp return_path("show", task), do: ~p"/tasks/#{task}"
end
