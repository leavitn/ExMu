defmodule Mud.World.Room.Movement do

  @moduledoc """
    Event information is communicated in format {:status, event}
    Events are initiated with either :init or :coerce
      init: Event request initiated by from_room,
        send :request to to_room, receive either :accept or :reject in response:
          case :reject -> send error to from_room
          case :accept -> send :commit to the to_room and from_room
      coerce: Force event. Do NOT send :request. Immediately send :commit to_room and from_room
  """

  alias Mud.World.{Room, Room.Content, Event, Zone}

  def init(room, character, to_room) when is_binary(character) do
    {:init, event_data(room, character, to_room)}
    |> Zone.event()
    room
  end

  defp event_data(room, character, to_room) do
    args = [
      object: Content.query(room, :mobs, character),
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
