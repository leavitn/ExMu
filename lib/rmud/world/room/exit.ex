defmodule Mud.World.Room.Exit do

  @defaults [:keyword, :from_room, :to_room, obvious?: true, dangerous?: false]

  defstruct @defaults

  def defaults(), do: @defaults

  @doc "sorts a list of exit keywords"
  def sort(keywords) do
    keywords
    |> Stream.map(&order/1)
    |> Enum.zip(keywords)
    |> Enum.sort()
    |> Enum.unzip()
    |> elem(1)
  end

  defp order(keyword) do
    case keyword do
      :north -> 0
      :south -> 1
      :east  -> 2
      :west  -> 3
      :up    -> 4
      :down  -> 5
      _ -> 99
    end
  end

end
