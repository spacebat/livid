defmodule Livid.Grid do
  defstruct [:cells, :cols, :rows, :data]

  def new(cols, rows, data \\ %{}, cell_data \\ nil) do
    cells = Enum.map(0..rows-1, fn y ->
      Enum.map(0..cols-1, fn x ->
        coord = {x, y}
        cell_data = case cell_data do
                      func when is_function(func) -> func.(coord)
                      _ -> %{}
                    end
        {coord, cell_data}
      end)
    end)
    |> List.flatten()
    |> Map.new()
    struct(__MODULE__, cells: cells, cols: cols, rows: rows, data: data)
  end

  def get_cell(cells, coord) do
    Map.get(cells.cells, coord)
  end

  def put_cell(cells, coord, data) do
    put_in(cells[:cells], [coord], data)
  end
end
