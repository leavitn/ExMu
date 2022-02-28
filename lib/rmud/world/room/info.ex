defmodule Mud.World.Room.Info do
  alias Mud.World.Room.Content

  def get_occupants(room, filter) do
    occupants = [room.contents.players | room.contents.mobs]
    case filter do
      :all ->
        Enum.map(occupants, &(&1.id))
      {:all_but, id} ->
        Stream.map(occupants, &(&1.id))
        |> Enum.reject(&(&1 == id))
    end
  end

  def get_any(room, n \\ 1, phrase) do
    Content.query(room, :all, n, phrase)
    |> error(:not_found)
  end

  def get_exit_path(room, keyword) do
    with {:ok, ex} <- get_exit(room, keyword), do:
      {:ok, ex.to_room}
  end

  def get_exit(room, keyword) do
    Map.get(room.exits, keyword)
    |> error({:exit, :not_found})
  end

  def get_subject(room, id) do
    Content.lookup(room, :mobs, id)
    |> error({:subject, :not_found})
  end

  def get_mob(room, n \\ 1, phrase) do
    Content.query(room, :mobs, n, phrase)
    |> error({:mob, :not_found})
  end

  def get_item(room, n \\ 1, phrase) do
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
