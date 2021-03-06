defmodule Mud.Repo do
  alias Mud.{World}
  alias World.{Room, Room.Exit}
  alias World.Room.Content.{Mob}

  def room({1,1,1} = id) do
    south = struct!(Exit, keyword: :south, from_room: id, to_room: {1,1,2})
    Room.new(name: "North Room", exits: %{south: south}, id: id)
  end

  def room({1,1,2} = id) do
    north = struct!(Exit, keyword: :north, from_room: id, to_room: {1,1,1})
    Room.new(name: "South Room", exits: %{north: north}, id: id)
  end

  def mob("orc captain" = name) do
    struct!(Mob, short_desc: name)
  end
end
