defmodule Nigiwiki.RoomContent do
  @moduledoc false

  use Agent

  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def get(room) do
    Agent.get(__MODULE__, &Map.get(&1, room, ""))
  end

  def put(room, value) do
    Agent.update(__MODULE__, &Map.put(&1, room, value))
  end
end
