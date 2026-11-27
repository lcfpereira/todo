defmodule Todo.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :completed, :boolean, default: false

    many_to_many :labels, Todo.Labels.Label,
      join_through: "task_labels",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :completed])
    |> validate_required([:title, :completed])
  end
end
