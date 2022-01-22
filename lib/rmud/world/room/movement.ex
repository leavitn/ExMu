defmodule Mud.Room.Movement do
  alias Mud.World.{Room.Content, Event, RoomServer}

  def init(character, to_room, from_room) do
    args = [
      character: character,
      to_room: to_room,
      from_room: from_room
    ]
    {:init, struct!(Event.Movement, args)}
    |> RoomServer.event()
  end

  def process({:request, event}, state), do: {consider(event), state}
  def process({:commit, event}, state) do
    {:ok, commit(event, state)}
  end

  # logic for accepting or rejecting move requests
  defp consider(event), do: {:accept, event}

  defp commit(event, room) do
    cond do
      event.from_room == room.id -> Content.delete(room, event.character)
      event.to_room == room.id -> Content.create(room, event.character)
    end
  end
end
