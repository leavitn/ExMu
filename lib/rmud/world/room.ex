defmodule Mud.World.Room do

  alias __MODULE__
  alias __MODULE__.{Exit, Content}
  alias Mud.MyEnum

  defstruct [:name, :id, exits: %{}, obvious_exits: [], content: %{}]

  def new(opts) do
    struct!(__MODULE__, opts)
    |> Map.put(:content, struct!(__MODULE__.Content, []))
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
  alias Mud.{World.Room, MyEnum, Character.Mob}
  defstruct mobs: []

  @doc "returns the result of a keyword search for an object in a room"
  def query(room, list_name, n \\ 1, phrase) do
    room.content
    |> Map.get(list_name, [])
    |> MyEnum.query(n, phrase)
  end

  @doc "returns the result of a id search for an object in a room"
  def lookup(room, list_name, id) do
    room.content
    |> Map.get(list_name, [])
    |> Enum.find(&(&1.id == id))
  end

  @doc "removes old object and replaces it with the new object in a room"
  def update(room, object) do
    case lookup(room, list_name(object), object.id) do
      nil -> create(room, object)
      old -> room |> delete(old) |> create(object)
    end
  end

  @doc "inserts an object into a room list. The list chosen is determined by struct"
  def create(room, object) do
    list_name = list_name(object)
    list = Map.get(room.content, list_name, [])
    put_in(room.content[list_name], [object | list])
  end

  @doc "deletes an object from a room"
  def delete(room, object) do
    list = list_name(object)
    revised_list = Enum.reject(room.content[list], &(&1.id == object.id))
    put_in(room.content[list], revised_list)
  end

  defp list_name(obj) do
    case obj do
      %Mob{} -> :mobs
      _ -> raise "Room doesn't contain list #{inspect obj}, please add to Room.list_name"
    end
  end

end

defmodule Mud.World.Room.Operations do
  alias Mud.World.Room
  alias Room.Content

  @spec spawn(%Room{}, :mob | :item, String.t()) :: %Room{}
  def spawn(room, type, template) do
    IO.puts "Spawning #{type} #{template} in room #{inspect room.id}"
    object = apply(Mud.Repo, type, [template])
    Content.create(room, object)
  end
end
