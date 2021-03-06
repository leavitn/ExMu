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

  alias Mud.World.{Room, Room.Content, Room.Info, Event, Zone}
  alias Mud.Character.Output.{OutputTerm, Pattern}
  alias Mud.Character

  # the parsed_term is NOT used for the event
  # Reason: to reduce amount of data passed around via message passing
  def init(room, character, to_room) do
    {:init, event_data(room, character, to_room)}
    |> Zone.event()
  end

  defp event_data(room, character, to_room) do
    args = [
      character: character,
      to_room: to_room,
      from_room: room.id
    ]
    struct!(Event.Movement, args)
    |> tap(&IO.inspect(&1))
  end

  def process({:request, event}, %Room{} = state), do: {consider(event, state), state}
  def process({:commit, event}, state), do: {:ok, commit(event, state)}

  # logic for accepting or rejecting move requests
  defp consider(event, _), do: {:accept, event}

  defp commit(event, room) do
    cond do
      event.from_room == room.id -> depart(event, room)
      event.to_room == room.id -> arrive(event, room)
    end
  end

  # input_term is created from event information
  # more verbose than if the parsed_term was passed in the event
  # but the reasoning is this reduces the amount of data deep copied between processes
  defp depart(event, room) do
    [
      subject: event.character,
      verb: :depart,
      dobj: Info.exit_keyword_lookup(room, event.to_room, :to_room),
      state: room
    ]
    |> OutputTerm.new()
    |> OutputTerm.notify(:all, Pattern.run(:standard))

    Content.delete(room, event.character)
  end

  defp arrive(event, room) do
    [
      subject: event.character,
      verb: :arrive,
      dobj: Info.exit_keyword_lookup(room, event.from_room, :from_room),
      state: room
    ]
    |> OutputTerm.new()
    |> OutputTerm.notify(:all, Pattern.run(:standard))

    :ok = Character.update_location(event.character.id, event.to_room) # move to Zone?
    Content.create(room, event.character)
  end
end
