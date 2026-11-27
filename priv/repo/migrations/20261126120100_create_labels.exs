defmodule Todo.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:labels, ["lower(name)"], name: :labels_lower_name_index)
  end
end
