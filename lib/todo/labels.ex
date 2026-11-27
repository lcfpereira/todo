defmodule Todo.Labels do
  @moduledoc """
  Reusable labels shared across tasks (global, many-to-many).
  """

  import Ecto.Query, warn: false
  alias Todo.Repo
  alias Todo.Labels.Label

  def list_labels do
    Repo.all(from l in Label, order_by: [asc: fragment("lower(?)", l.name)])
  end

  def get_label!(id), do: Repo.get!(Label, id)

  def get_label_by_name(name) when is_binary(name) do
    Repo.one(
      from l in Label, where: fragment("lower(?)", l.name) == ^String.downcase(String.trim(name))
    )
  end

  def create_label(attrs) do
    %Label{} |> Label.changeset(attrs) |> Repo.insert()
  end

  def change_label(%Label{} = label, attrs \\ %{}), do: Label.changeset(label, attrs)

  @doc """
  Returns the label with the given name (case-insensitive), creating it if needed.
  """
  def get_or_create_label(name) when is_binary(name) do
    name = String.trim(name)

    case get_label_by_name(name) do
      %Label{} = label ->
        {:ok, label}

      nil ->
        create_label(%{name: name})
    end
  end

  @doc """
  Deleting a label detaches it from tasks (join rows cascade); tasks are kept.
  """
  def delete_label(%Label{} = label), do: Repo.delete(label)

  @doc """
  Splits a comma-separated string into trimmed, non-blank names,
  de-duplicated case-insensitively.
  """
  def parse_names(nil), do: []

  def parse_names(string) when is_binary(string) do
    string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq_by(&String.downcase/1)
  end

  @doc """
  Resolves form params (`"label_ids"` list and `"new_labels"` comma-separated
  string) into a list of labels, creating new ones as needed.

  Must run inside a transaction when the caller wants all-or-nothing behaviour.
  Returns `{:ok, labels}` or `{:error, message}`.
  """
  def resolve_labels(attrs) do
    ids = attrs |> Map.get("label_ids", []) |> List.wrap() |> parse_ids()
    existing = Repo.all(from l in Label, where: l.id in ^ids)

    result =
      if length(existing) == length(ids) do
        create_from_names(Map.get(attrs, "new_labels"))
      else
        {:error, "Some selected labels no longer exist, please review the selection"}
      end

    with {:ok, created} <- result do
      {:ok, Enum.uniq_by(existing ++ created, & &1.id)}
    end
  end

  @doc """
  Parses submitted ids, dropping blanks and anything that is not an integer.
  """
  def parse_ids(ids) do
    ids
    |> Enum.flat_map(fn
      id when is_integer(id) ->
        [id]

      id when is_binary(id) ->
        case Integer.parse(id) do
          {int, ""} -> [int]
          _ -> []
        end

      _ ->
        []
    end)
    |> Enum.uniq()
  end

  defp create_from_names(names) do
    names
    |> parse_names()
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, acc} ->
      case get_or_create_label(name) do
        {:ok, label} -> {:cont, {:ok, [label | acc]}}
        {:error, cs} -> {:halt, {:error, error_message(name, cs)}}
      end
    end)
  end

  defp error_message(name, %Ecto.Changeset{} = changeset) do
    [message | _] =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
      |> Map.values()
      |> List.flatten()

    "#{name}: #{message}"
  end
end
