defmodule Mud.World.Room.Content.Defaults do
  @defaults [
    :id, :short_desc, aliases: []
  ]

  def get(), do: @defaults
end

defmodule Mud.World.Room.Content.Mob do
  defstruct Mud.World.Room.Content.Defaults.get()
end

defmodule Mud.World.Room.Content do
  alias Mud.{World.Room, MyEnum}
  alias __MODULE__.{Mob}

  defstruct features: [], users: [], mobs: [], items: []

  def spawn(room, id, type, template) do
    IO.puts "Spawning #{type} #{template} in room #{inspect room.id}"
    object = apply(Mud.Repo, type, [template]) |> Map.put(:id, id)
    IO.inspect object
    create(room, object)
  end

  @doc "returns the result of a keyword search for an object in a room"
  def query(room, list_name, n \\ 1, phrase)
  def query(room, :all, n, phrase) do
    [:features, :users, :mobs, :items]
    |> MyEnum.short_circuit(&query(room, &1, n, phrase))
  end
  def query(room, list_name, n, phrase) do
    room.content
    |> Map.get(list_name, [])
    |> MyEnum.query(n, phrase)
  end

  @doc "returns the result of an id search for an object in a room"
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
    new_content = Map.put(room.content, list_name, [object | list])
    Map.put(room, :content, new_content)
  end

  @doc "deletes an object from a room"
  def delete(room, object) do
    list_name = list_name(object)
    revised_list =
      Map.get(room.content, list_name, [])
      |> Enum.reject(&(&1.id == object.id))
    new_content = Map.put(room.content, list_name, revised_list)
    Map.put(room, :content, new_content)
  end

  defp list_name(obj) do
    case obj do
      %Mob{} -> :mobs
      _ -> raise "Room doesn't contain list #{inspect obj}, please add to Room.list_name"
    end
  end

end

defmodule Mud.World.Room.Commands do
  alias Mud.World.Room.Info

  @commands %{
    go: true
  }

  def validate(verb), do: Map.get(@commands, verb, false)

  def go(room, term) do
    alias Mud.World.Room.Movement
    with {:ok, character} <- Info.find_id(room, term.subject),
         {:ok, to_room} <- Info.find_exit_path(room, term.dobj) do
      Movement.init(room, character, to_room)
    end
  end

end

defmodule Mud.World.Room do
  alias __MODULE__
  alias __MODULE__.{Exit, Content}

  defstruct [
    :name,
    :id,
    exits: %{},
    obvious_exits: [],
    content: struct!(Content)
  ]

  def new(opts) do
    struct!(__MODULE__, opts)
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

  def handle_input(room, parsed_term) do
    with {:ok, fun} <- __MODULE__.Info.get_verb_fun(room, parsed_term.verb), do:
      fun.(parsed_term)
  end
end
