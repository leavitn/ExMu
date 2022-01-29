defmodule Mud.World.Room.Movement do
  alias Mud.World.{Room, Room.Content, Event, Zone}

  def init(room, character, to_room) when is_binary(character) do
    {:init, event_data(room, character, to_room)}
    |> Zone.event()
    room
  end

  def coerce(room, character, to_room) do
    {:coerce, event_data(room, character, to_room)}
    |> Zone.event()
    room
  end

  defp event_data(room, character, to_room) do
    args = [
      character: Content.query(room, :mobs, character),
      to_room: to_room,
      from_room: room.id
    ]
    struct!(Event.Movement, args)
  end

  def process({:request, event}, %Room{} = state), do: {consider(event, state), state}
  def process({:commit, event}, state), do: {:ok, commit(event, state)}

  # logic for accepting or rejecting move requests
  defp consider(event, _), do: {:accept, event}

  defp commit(event, room) do
    cond do
      event.from_room == room.id -> Content.delete(room, event.character)
      event.to_room == room.id -> Content.create(room, event.character)
    end
  end

end
