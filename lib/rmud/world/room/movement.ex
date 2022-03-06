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
  alias Mud.Character.Input
  alias Input.{InputTerm, Pattern}

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
      event.to_room == room.id -> arrive(event, Content.create(room, event.character))
    end
  end

  # input_term is created from event information
  # more verbose than if the parsed_term was passed in the event
  # but the reasoning is this reduces the amount of data deep copied between processes
  defp depart(event, room) do
    opts = [
      subject: event.character,
      verb: :depart,
      dobj: Info.exit_keyword_lookup(room, event.to_room, :to_room),
      state: room
    ]
    opts
    |> InputTerm.new()
    |> InputTerm.notify(:all, Pattern.run(:standard))
    |> Map.get(:events)
    |> List.first()
    |> IO.inspect # TODO replace with notification to Character processes

    Content.delete(room, event.character)
  end

  defp arrive(event, room) do
    direction = Info.exit_keyword_lookup(room, event.to_room, :from_room)
    opts = [
      subject: event.character,
      verb: :arrive,
      dobj: direction,
      state: room
    ]
    opts
    |> InputTerm.new()
    |> InputTerm.notify(:all, Pattern.run(:dobj, preposition: "from the"))
    |> Map.get(:events)
    |> List.first()
    |> IO.inspect # TODO replace with notification to Character processes

    room
  end
end
