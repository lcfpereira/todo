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
    Task |> preload(:labels) |> Repo.all()
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Task |> preload(:labels) |> Repo.get!(id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs) do
    save_with_labels(%Task{labels: []}, attrs, &Repo.insert/1)
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
    save_with_labels(Repo.preload(task, :labels), attrs, &Repo.update/1)
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

  # Labels are only touched when the params carry "label_ids" or "new_labels"
  # (the task form). New labels are created inside the same transaction as the
  # task so an invalid task never leaves orphan labels behind.
  defp save_with_labels(task, attrs, persist) do
    Repo.transaction(fn ->
      changeset = task |> Task.changeset(attrs) |> put_labels(attrs)

      case persist.(changeset) do
        {:ok, task} -> task
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp put_labels(changeset, attrs) do
    if Map.has_key?(attrs, "label_ids") or Map.has_key?(attrs, "new_labels") do
      case Todo.Labels.resolve_labels(attrs) do
        {:ok, labels} -> Ecto.Changeset.put_assoc(changeset, :labels, labels)
        {:error, message} -> Ecto.Changeset.add_error(changeset, :new_labels, message)
      end
    else
      changeset
    end
  end
end
