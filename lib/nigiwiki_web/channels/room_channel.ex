defmodule NigiwikiWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("new:msg", message, socket) do
    broadcast! socket, "new:msg", message
    {:noreply, socket}
  end
end
