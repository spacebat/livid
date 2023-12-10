defmodule LividWeb.GridLive do
  use LividWeb, :live_view
  require Logger

  @period_ms 2_000
  @persist_ms 10_000
  @persist_us @persist_ms * 1_000_000

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

    socket = timer_start(socket)

    {:ok, assign(socket, grid: grid)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={LividWeb.Components.GridComponent} id="grid" grid={@grid} />
    """
  end

  def handle_event("cell_clicked", params, socket) do
    :erlang.garbage_collect
    {:noreply, push_event(socket, "alert", %{message: "Garbage collected"})}
  end

  @impl true
  def handle_event("mousemove", params, socket) do
    coords = {params["x"], params["y"]}
    grid = socket.assigns.grid
    value = grid.cells[coords]
    count = value.count + 1
    new_grid = put_in(grid.cells[coords], %{count: count, shade: shade(count), fill: fill(count)})
    socket = timer_start(socket)
    {:noreply, assign(socket, grid: new_grid, last_event_time: System.monotonic_time)}
  end

  @impl true
  def handle_info(:tick, socket) do
    Logger.debug("HANDLE INFO :tick in #{__MODULE__}")
    now = System.monotonic_time
    last_time = Map.get(socket.assigns, :last_event_time, now - @persist_us)
    socket = if (now - last_time) < @persist_us do
      cells = socket.assigns.grid.cells
      |> Map.new(fn {k, v} = pair ->
        if v.count > 0 do
          count = v.count - 1
          {k, %{count: count, shade: shade(count), fill: fill(count)}}
        else
          pair
        end
      end)
      grid = Map.put(socket.assigns.grid, :cells, cells)
      assign(socket, grid: grid)
    else
      :erlang.garbage_collect
      timer_stop(socket)
    end
    {:noreply, socket}
  end

  defp timer_start(socket) do
    case Map.fetch(socket, :timer) do
      {:ok, _timer} -> socket
      _ ->
        {:ok, timer} = :timer.send_interval(@period_ms, :tick)
        Map.put(socket, :timer, timer)
    end
  end

  defp timer_stop(socket) do
    case Map.fetch(socket, :timer) do
      {:ok, timer} ->
        {:ok, :cancel} = :timer.cancel(timer)
        Map.delete(socket, :timer)
      _ -> socket
    end
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

  @impl true
  def terminate(_reason, state) do
    result = Map.fetch(state, :timer)
    case result do
      {:ok, ref} -> :timer.cancel(ref)
      _ -> nil
    end
  end
end
