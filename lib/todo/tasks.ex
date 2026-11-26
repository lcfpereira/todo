defmodule Todo.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Todo.Repo

  alias Todo.Tasks.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Returns tasks grouped for the index view. See `group_tasks/2`.

  `today` defaults to `Date.utc_today/0` and can be injected for tests.
  """
  def list_grouped_tasks(today \\ Date.utc_today()) do
    list_tasks() |> group_tasks(today)
  end

  @doc """
  Groups tasks into overdue, weeks of days, and undated tasks. Pure function.

    * `:overdue` - incomplete tasks due before `today`
    * `:weeks` - `[%{start: monday, days: [%{date: date, tasks: [task]}]}]`, weeks start
      on Monday, only days with tasks are listed, and past weeks are not shown.
      Completed tasks stay on their day.
    * `:no_date` - tasks without a due date

  Tasks within a group are ordered by `inserted_at` ascending (then id).
  """
  def group_tasks(tasks, today \\ Date.utc_today()) do
    sorted =
      tasks |> Enum.sort_by(& &1.id) |> Enum.sort_by(& &1.inserted_at, DateTime)

    current_week = beginning_of_week(today)

    {undated, dated} = Enum.split_with(sorted, &is_nil(&1.due_date))

    {overdue, dated} =
      Enum.split_with(dated, &(not &1.completed and Date.compare(&1.due_date, today) == :lt))

    weeks =
      dated
      |> Enum.reject(&(Date.compare(beginning_of_week(&1.due_date), current_week) == :lt))
      |> Enum.group_by(& &1.due_date)
      |> Enum.sort_by(fn {date, _} -> date end, Date)
      |> Enum.chunk_by(fn {date, _} -> beginning_of_week(date) end)
      |> Enum.map(fn [{first, _} | _] = days ->
        %{
          start: beginning_of_week(first),
          days: Enum.map(days, fn {date, tasks} -> %{date: date, tasks: tasks} end)
        }
      end)

    %{overdue: overdue, weeks: weeks, no_date: undated}
  end

  defp beginning_of_week(date), do: Date.beginning_of_week(date, :monday)

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end
end
