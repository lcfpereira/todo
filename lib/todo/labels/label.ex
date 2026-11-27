defmodule Todo.Labels.Label do
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    field :name, :string

    many_to_many :tasks, Todo.Tasks.Task, join_through: "task_labels"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name])
    |> validate_length(:name, max: 30)
    |> unique_constraint(:name, name: :labels_lower_name_index)
  end
end
