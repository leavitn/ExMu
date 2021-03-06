defmodule Mud.World.Zone.State do
  defstruct [:id, mob_lookup: %{}]

  def update_mob_location(state, mob_id, room_id) do
    new_lookup = Map.put(state.mob_lookup, mob_id, room_id)
    Map.put(state, :lookup, new_lookup)
  end
end

defmodule Mud.World.Zone do
  @moduledoc """
    Negotiates inter-room events such as movement, ranged attacks, door state
    Tracks locations of entities in the zone
    Can also put the weather state in here and broadcast weather events to rooms
  """

  use GenServer
  alias Mud.Registry
  alias __MODULE__

  def start_link(zone_id) do
    IO.puts "Starting zone #{inspect zone_id}"
    GenServer.start_link(__MODULE__, zone_id, name: via_tuple(zone_id))
  end

  def via_tuple(zone_id) do
    Registry.via_tuple({__MODULE__, zone_id})
  end

  def event(zone_id, {status, _} = event) do
    case status do
      x when x in [:init, :coerce] ->
        GenServer.cast(via_tuple(zone_id), {:event, event})
      :request ->
        GenServer.call(via_tuple(zone_id), {:event, event})
    end
  end

  def event({status, event}) do
    case get_zones(event) do
      {same, same} -> event(same, {status, event})
      _ -> raise "Multiple zones not yet supported" # World.event(event) TODO
    end
  end

  defp get_zones(event) do
    id = fn {world, zone, _} -> {world, zone} end
    to = id.(event.to_room)
    from = id.(event.from_room)
    {to, from}
  end

  # Implementation Functions

  @impl true
  def init(zone_id) do
    {:ok, struct!(Zone.State, id: zone_id)}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    {:noreply, Zone.Event.process(event, state)}
  end

  @impl true
  def handle_call({:event, event}, _, state) do
    {reply, state} = Zone.Event.consider(event, state)
    {:reply, reply, state}
  end
end

defmodule Mud.World.Zone.Event do
  alias Mud.World.RoomServer
  alias Mud.World.Zone.State

  @moduledoc """
    Event information is communicated in format {:status, event}
    Events are initiated with either :init or :coerce
      init: Event request initiated by from_room,
        send :request to to_room, receive either :accept or :reject in response:
          case :reject -> send error to from_room
          case :accept -> send :commit to the to_room and from_room
      coerce: Force event. Do NOT send :request. Immediately send :commit to_room and from_room
  """

  def process({:init, event}, state) do
    RoomServer.event(event.to_room, {:request, event}) # reply will be :accept or :reject
    |> handle_reply(state)
  end

  def consider({:request, event}, state) do
    # function for deciding whether to :accept or :reject request
    {{:accept, event}, state}
  end

  def handle_reply({status, event}, state) when status in [:accept, :reject] do
    case status do
      :reject ->
        RoomServer.event(event.from_room, {:reject, event})
        state
      :accept ->
        :ok = RoomServer.event(event.from_room, {:commit, event})
        :ok = RoomServer.event(event.to_room, {:commit, event})
        State.update_mob_location(state, event.character.id, event.to_room)
    end
  end

end
