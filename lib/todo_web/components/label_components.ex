defmodule TodoWeb.LabelComponents do
  @moduledoc "Function components for displaying task labels."
  use Phoenix.Component

  attr :labels, :list, required: true
  attr :id, :string, required: true

  def label_badges(assigns) do
    ~H"""
    <div :if={@labels != []} id={@id} class="flex flex-wrap gap-1">
      <span
        :for={label <- @labels}
        id={"#{@id}-label-#{label.id}"}
        class="inline-flex items-center rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary"
      >
        {label.name}
      </span>
    </div>
    """
  end
end
