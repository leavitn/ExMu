defmodule Mud.World do
  @moduledoc """
    Negotiates inter-zone events such as movement between zones, doors, ranged attacks, etc.
  """
  alias Mud.{Registry, World.ZoneSupervisor, World.RoomSupervisor}
  alias Mud.World.Room
  use DynamicSupervisor

  def start_link(world_id) do
    IO.puts "starting World Supervisor"
    DynamicSupervisor.start_link(__MODULE__, world_id, name: via_tuple(world_id))
  end

  def via_tuple(world_id) do
    Registry.via_tuple({__MODULE__, world_id})
  end

  def start_zone(world_id, zone_id) do
    DynamicSupervisor.start_child(via_tuple(world_id), {ZoneSupervisor, zone_id})
  end

  def start_room({_, zone_id, room_id} = id) do
    RoomSupervisor.start_room(zone_id, room_id)
  end

  defp zone_pid({world_id, zone_id, _}) do
    with {:error, {:already_started, pid}} <- start_zone(world_id, zone_id), do:
      pid
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def child_spec(world_id) do
    %{
      id: {__MODULE__, world_id},
      start: {__MODULE__, :start_link, [world_id]},
      type: :supervisor
    }
  end
end
