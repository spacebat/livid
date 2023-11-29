defmodule LividWeb.GridLive do
  use LividWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {cols, rows} = {16, 16}
    cells = Enum.map(0..rows-1,
      fn y ->
        Enum.map(0..cols-1, fn x -> {{x, y}, %{count: 0, shade: shade(0), fill: fill(0)}} end)
      end)
      |> List.flatten()
      |> Map.new()
    {width, height} = {600, 600}
    cell_size = round(width / rows)
    grid = %{cells: cells, width: width, height: height, rows: rows, cols: cols, cell_size: cell_size}
    {:ok, assign(socket, grid: grid)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={LividWeb.Components.GridComponent} id="grid" grid={@grid} />
    """
  end

  @impl true
  def handle_event("mousemove", params, socket) do
    coords = {params["x"], params["y"]}
    grid = socket.assigns.grid
    value = grid.cells[coords]
    count = value.count + 1
    new_grid = put_in(grid.cells[coords], %{count: count, shade: shade(count), fill: fill(count)})

    {:noreply, assign(socket, grid: new_grid)}
  end

  defp shade(count) do
    255 - rem(count * 8, 255)
  end

  defp hex(number) do
    number
    |> shade()
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  defp fill(num) when is_integer(num) do
    fill(hex(num))
  end

  defp fill(hex) when is_binary(hex) do
    "##{hex}#{hex}#{hex}"
  end
end
