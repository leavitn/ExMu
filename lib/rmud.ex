defmodule Mud do
  alias Mud.{World, Character, Registry, Telnet}

  @default_loc {1,1,1}

  def system_start(id) do
    children = [
      Registry,
      {World, id},
      Character.UserSupervisor,
      Telnet.Listener
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start() do
    system_start(1)
    World.start_zone(1, zone_id(1,1))
    Enum.each(1..2, &World.start_room(zone_id(1,1), room_id(1, 1, &1)))
  end

  def spawn() do
    id = Mud.Id.generate()
    op = %{
      module: Mud.World.Room.Content,
      fun: :spawn,
      args: [id, :mob, "orc captain"]
    }
    World.RoomServer.operation({1,1,1}, op)
    id
  end

  def move() do
    start()
    id = spawn()

    term = %{
      subject: id,
      dobj: :south,
      verb: :go
    }
    Mud.World.RoomServer.input({1,1,1}, term)
  end

  def spawn2() do
    opts = %{
      id: Mud.Id.generate(),
      template_id: "orc captain",
      room_id: {1,1,1}
    }
    start()
    Character.UserSupervisor.start_user(opts)
    Character.get(opts.id)
    opts.id
  end

  def dump() do
    id = spawn2()
    term = %{
      subject: id,
      verb: :dump
    }
    Character.input(id, term)
  end

  def room_id(world_id, zone_id, room_id), do: {world_id, zone_id, room_id}
  def zone_id(world_id, zone_id), do: {world_id, zone_id}

  def default_location(), do: @default_loc
end
