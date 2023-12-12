defmodule Livid.GridServer do
  use GenServer
  require Logger
  alias Livid.Grid
  alias Phoenix.PubSub

  @period_ms 2_000
  @persist_ms 120_000
  @persist_us @persist_ms * 1_000_000

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    {cols, rows} = {18, 18}
    {width, height} = {600, 600}
    cell_size = round(width / rows)
    grid = Grid.new(cols, rows,
      %{width: width, height: height, cell_size: cell_size},
      fn _ -> %{count: 0, shade: shade(0), fill: fill(0)} end
    )
    state = %{grid: grid}
    state = timer_start(state)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  @impl true
  def handle_cast({:increment, coord}, state) do
    count = state.grid.cells[coord].count + 1
    state = put_in(state.grid.cells[coord], %{count: count, shade: shade(count), fill: fill(count)})
    PubSub.broadcast(Livid.PubSub, "grid", {:grid_state, state.grid})
    state = timer_start(state)
    {:noreply, Map.put(state, :last_event_time, System.monotonic_time)}
  end

  @impl true
  def handle_info(:tick, state) do
    Logger.debug("HANDLE INFO :tick in #{__MODULE__}")
    now = System.monotonic_time
    last_time = Map.get(state, :last_event_time, now - @persist_us)
    state = if (now - last_time) < @persist_us do
      cells = state.grid.cells
      |> Map.new(fn {k, v} = pair ->
        if v.count > 0 do
          count = v.count - 1
          {k, %{count: count, shade: shade(count), fill: fill(count)}}
        else
          pair
        end
      end)
      grid = Map.put(state.grid, :cells, cells)
      Map.put(state, :grid, grid)
    else
      :erlang.garbage_collect
      timer_stop(state)
    end
    PubSub.broadcast(Livid.PubSub, "grid", {:grid_state, state.grid})
    {:noreply, state}
  end

  defp timer_start(state) do
    case Map.fetch(state, :timer) do
      {:ok, _timer} -> state
      _ ->
        {:ok, timer} = :timer.send_interval(@period_ms, :tick)
        Map.put(state, :timer, timer)
    end
    |> (fn x -> IO.inspect(x.timer); x end).()
  end

  defp timer_stop(state) do
    case Map.fetch(state, :timer) do
      {:ok, timer} ->
        {:ok, :cancel} = :timer.cancel(timer)
        Map.delete(state, :timer)
      _ -> state
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
