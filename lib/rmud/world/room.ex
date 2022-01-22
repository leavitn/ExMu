defmodule Mud.World.Room do

  alias Mud.World.{Room, Room.Exit}
  alias Mud.MyEnum

  defstruct [:content, :name, :id, exits: %{}, obvious_exits: []]

  def new(opts) do
    struct!(__MODULE__, opts)
    |> Map.put_new(:content, struct!(__MODULE__.Content, []))
    |> update_obvious_exits()
  end

  defp update_obvious_exits(%{exits: %{}} = room), do: room
  defp update_obvious_exits(room) do
    obvious =
      room.exits
      |> Map.values()
      |> Stream.filter(&(&1.obvious?))
      |> Stream.map(&(&1.keyword))
      |> Exit.sort()
    %Room{room | obvious_exits: obvious}
  end

end

defmodule Mud.World.Room.Content do
  alias Mud.World.{Mob}
  alias Mud.MyEnum
  defstruct mobs: []

  @doc "returns the result of a keyword search for an object in a room"
  def query(room, list_name, n \\ 1, phrase) do
    room
    |> Map.get(list_name, [])
    |> MyEnum.query(n, phrase)
  end

  @doc "returns the result of a id search for an object in a room"
  def lookup(room, list_name, id) do
    room
    |> Map.get(list_name, [])
    |> Enum.find(&(&1.id == id))
  end

  @doc "removes old object and replaces it with the new object in a room"
  def update(room, old_obj, new_obj) do
    room
    |> delete(old_obj)
    |> create(new_obj)
  end

  @doc "inserts an object into a room list. The list chosen is determined by struct"
  def create(room, object) do
    list = list_name(object)
    current_list = Map.get(room, list, [])
    Map.put(room, list, [object | current_list])
  end

  @doc "deletes an object from a room"
  def delete(room, object) do
    list = list_name(object)
    current_list = Map.get(room, list, [])
    revised_list = MyEnum.reject_n(current_list, 1, &(&1 == object))
    Map.put(room, list, revised_list)
  end

  defp list_name(obj) do
    case obj do
      _ -> raise "Room doesn't contain list #{inspect obj}, please add to Room.list_name"
    end
  end

end
