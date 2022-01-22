defmodule Mud.Repo do
  alias Mud.World.{Room, Room.Exit}

  def room({1,1,1} = id) do
    south = struct!(Exit, keyword: :south, from_room: id, to_room: {1,1,2})
    struct!(Room, name: "North Room", exits: %{south: south}, id: id)
  end

  def room({1,1,2} = id) do
    north = struct!(Exit, keyword: :north, from_room: id, to_room: {1,1,1})
    struct!(Room, name: "South Room", exits: %{north: north}, id: id)
  end
end
