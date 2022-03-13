defmodule Mud.Character.Output.Template do
  def room(%{dobj: room}) do
    [
      room.name, ?\n,
      "Obvious exits: #{inspect room.obvious_exits}", ?\n,
      "#{inspect room.content}", ?\n
    ]
  end
end
