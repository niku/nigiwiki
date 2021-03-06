defmodule NigiwikiWeb.RoomChannel do
  @moduledoc """
  Defines a Room Channel.
  """

  use NigiwikiWeb, :channel

  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      payload = %{
        "body" => Nigiwiki.RoomContent.get("room:lobby")
      }

      send(self(), :after_join)
      {:ok, payload, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", NigiwikiWeb.Presence.list(socket))

    {:ok, _} =
      NigiwikiWeb.Presence.track(socket, socket.assigns.user_id, %{
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    Nigiwiki.RoomContent.put("room:lobby", payload["body"])
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
