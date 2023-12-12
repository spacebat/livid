defmodule LividWeb.GridLive do
  use LividWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Livid.PubSub, "grid")
    grid = GenServer.call(Livid.GridServer, :get_grid)
    {:ok, assign(socket, grid: grid)}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
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
    GenServer.cast(Livid.GridServer, {:increment, coords})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:grid_state, grid}, socket) do
    {:noreply, assign(socket, grid: grid)}
  end
end
