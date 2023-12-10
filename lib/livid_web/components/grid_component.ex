defmodule LividWeb.Components.GridComponent do
  use LividWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <svg width={@grid.width} height={@grid.height} xmlns="http://www.w3.org/2000/svg">
    <%= for {{col, row}, value} <- @grid.cells do %>
      <rect x={row * @grid.cell_size} y={col * @grid.cell_size}
            width={@grid.cell_size - 2} height={@grid.cell_size - 2}
            fill={value.fill} id={"cell-#{col}-#{row}"}
            phx-hook="GridCell" phx-click="cell_clicked"/>
      <text x={(row+1) * @grid.cell_size - (@grid.cell_size / 2)}
            y={(col+1) * @grid.cell_size - (@grid.cell_size / 2)}
            font-size="14" text-anchor="middle" alignment-baseline="central"
            style="pointer-events: none"
            fill={if value.shade > 128, do: "black", else: "white"}>
        <%= value.count %>
      </text>
    <% end %>
    </svg>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
