defmodule Mud.World.Zone.State do
  defstruct [:id, mob_lookup: %{}]

  def init(opts), do: struct!(__MODULE__, opts)
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
  alias Mud.{Registry, World}
  alias World.{Zone.State, RoomServer}

  def start_link(zone_id) do
    IO.puts "Starting zone #{inspect zone_id}"
    GenServer.start_link(__MODULE__, zone_id, name: via_tuple(zone_id))
  end

  def via_tuple(zone_id) do
    Registry.via_tuple({__MODULE__, zone_id})
  end

  def event(zone_id, event) do
    GenServer.cast(via_tuple(zone_id), {:event, event})
  end

  def event(event) do
    case get_zones(event) do
      {same, same} -> event(same, event)
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
    {:ok, State.init(id: zone_id)}
  end

  def handle_cast({:event, {:init, _} = event}, _, state) do
    {:noreply, handle_event(event, state)}
  end

  defp handle_event({:init, event}, state) do
    case RoomServer.event(event.to_room, {:request, event}) do
      {:reject, event} ->
        RoomServer.event(event.from_room, {:reject, event})
        state
      {:accept, event} ->
        :ok = RoomServer.event(event.from_room, {:commit, event})
        :ok = RoomServer.event(event.to_room, {:commit, event})
        State.update_mob_location(state, event.character.id, event.to_room)
    end
  end

end
