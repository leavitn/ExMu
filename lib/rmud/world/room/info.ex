defmodule Mud.World.Room.Info do
  alias Mud.World.Room.Content

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

  def get_mob_ids(room, []) do
    result =
      room.content.users ++ room.content.mobs
      |> Enum.map(&(&1.id))
    {:ok, result}
  end

  def find_any(room, n \\ 1, phrase) do
    Content.query(room, :all, n, phrase)
    |> error(:not_found)
  end

  def find_exit_path(room, keyword) do
    with {:ok, ex} <- find_exit(room, keyword), do:
      {:ok, ex.to_room}
  end

  def find_exit(room, keyword) do
    Map.get(room.exits, keyword)
    |> error({:exit, :not_found})
  end

  def find_subject(room, id) do
    Content.lookup(room, :mobs, id)
    |> error({:subject, :not_found})
  end

  def find_mob(room, n \\ 1, phrase) do
    Content.query(room, :mobs, n, phrase)
    |> error({:mob, :not_found})
  end

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
