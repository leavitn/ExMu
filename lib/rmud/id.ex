defmodule Mud.Id do
  use Puid

  def type_to_lead(type) do
    case type do
      Mud.World.Item -> "I#"
      Mud.World.Mob  -> "M#" 
    end
  end
end
