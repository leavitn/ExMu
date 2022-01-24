defmodule Mud do
  alias Mud.World
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

  def room_id(world_id, zone_id, room_id), do: {world_id, zone_id, room_id}
  def zone_id(world_id, zone_id), do: {world_id, zone_id}
  #def room_id(world_id, zone_id, room_id), do: zone_id(world_id, zone_id) <> ",#{room_id}"
  #def zone_id(world_id, zone_id), do: "#{world_id},#{zone_id}"

end
