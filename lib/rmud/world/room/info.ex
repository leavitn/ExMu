defmodule Mud.World.Room.Info do
  alias Mud.World.Room.Content

  @doc """
    Recieves a verb and returns either the corresponding command function OR error
      if the verb cannot be performed in the room
  """
  def get_verb_fun(room, verb) do
    alias Mud.World.Room.Commands
    case Commands.validate(verb) do
      true -> {:ok, &apply(Commands, verb, [room, &1])}
      false -> {:error, {:command, :not_found}}
    end

  end

  @doc """
    returns the first exit key that matches room_id
  """
  def exit_keyword_lookup(room, room_id, side) when side in [:to_room, :from_room] do
    room_exit =
      room.exits
      |> Map.values()
      |> Enum.find(&Map.get(&1, side) == room_id)
    case room_exit do
      %{} -> room_exit.keyword
      _ -> :nowhere
    end
  end

  @doc """
    returns list of mob ids in the room
    for the purpose of broadcasting notifications to their character processes
  """
  def get_mob_ids(room, []) do
    result =
      room.content.users ++ room.content.mobs
      |> Enum.map(&(&1.id))
    {:ok, result}
  end

  @doc "searches all lists in the room for a match"
  def find_any(room, n \\ 1, phrase) do
    Content.query(room, :all, n, phrase)
    |> error(:not_found)
  end

  @doc "returns the :to_room room_id for the exit keyword if a match exists"
  def find_exit_path(room, keyword) do
    with {:ok, ex} <- find_exit(room, keyword), do:
      {:ok, ex.to_room}
  end

  def find_exit(room, keyword) do
    Map.get(room.exits, keyword)
    |> error({:exit, :not_found})
  end

  @doc "searches room contents by id"
  def find_id(room, id) do
    Content.lookup(room, :mobs, id)
    |> error({:subject, :not_found})
  end

  @doc "searches for a mob via a binary phrase"
  def find_mob(room, n \\ 1, phrase) do
    Content.query(room, :mobs, n, phrase)
    |> error({:mob, :not_found})
  end

  @doc "searches for an item via a binary phrase"
  def find_item(room, n \\ 1, phrase) do
    Content.query(room, :items, n, phrase)
    |> error({:item, :not_found})
  end
  
  defp error(result, error_message) do
    case result do
      x when x in [nil, false] -> {:error, error_message}
      _ -> {:ok, result}
    end
  end
end
