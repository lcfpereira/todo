defmodule Todo.Repo.Migrations.CreateTaskLabels do
  use Ecto.Migration

  def change do
    create table(:task_labels, primary_key: false) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :label_id, references(:labels, on_delete: :delete_all), null: false
    end

    create unique_index(:task_labels, [:task_id, :label_id])
    create index(:task_labels, [:label_id])
  end
end
