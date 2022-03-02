defmodule Mud.World.Event.Movement do
  defstruct [:to_room, :from_room, :character, :reason]
end

defmodule Mud.World.Event do
  def module({_, event}), do: type(event)

  defp type(%{__struct__: module}) do
    Module.split(module) |> List.last()
  end
end
