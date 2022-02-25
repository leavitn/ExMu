defmodule Mud.Id do

  use Puid

  alias Mud.Character.Mob

  def create(type) do
    type(type) <> generate()
  end

  def type(type) do
    case type do
      Mob  -> "m#"
      _ -> ""
    end
  end

  def id_to_type(id) do
    case id do
      "m#" <> _ -> :mob
      "i#" <> _ -> :item
    end
  end

end
