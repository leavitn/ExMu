defmodule Mud.Id do

  use Puid

  alias Mud.Character.Mob

  def create(type) do
    type(type) <> generate()
  end

  def type(type) do
    case type do
      Mob  -> "M#"
      _ -> ""
    end
  end

end
