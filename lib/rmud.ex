defmodule Mud do
  alias Mud.{World}

  @default_loc {1,1,1}

  def system_start(id) do
    children = [
      Mud.Registry,
      {World, id}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start() do
    system_start(1)
    World.start_zone(1, zone_id(1,1))
    Enum.each(1..2, &World.start_room(zone_id(1,1), room_id(1, 1, &1)))
  end

  def spawn() do
    op = %{
      module: Mud.World.Room.Content,
      fun: :spawn,
      args: [:mob, "orc captain"]
    }
    World.RoomServer.operation({1,1,1}, op)
  end

  def move() do
    spawn()
    op = %{
      module: Mud.World.Room.Movement,
      fun: :init,
      args: ["orc captain", {1,1,2}]
    }
    World.RoomServer.operation({1,1,1}, op)
  end

  def room_id(world_id, zone_id, room_id), do: {world_id, zone_id, room_id}
  def zone_id(world_id, zone_id), do: {world_id, zone_id}

  def default_location(), do: @default_loc
end
