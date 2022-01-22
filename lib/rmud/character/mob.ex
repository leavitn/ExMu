# Mob is shorthand for "mobile",
# i.e. things that move around such as players / monsters

defmodule Mud.Character.Mob do

  alias __MODULE__

  defstruct [
    :id,
    :name,
    :noun,
    aliases: [],
    inventory: []
  ]
  def new(opts), do: struct!(__MODULE__, opts)

  def mob?(%Mob{}), do: true
  def mob?(_), do: false
end

defmodule Mud.Character.Mob.Inventory do
  alias Mud.Character.Mob
  alias Mud.MyEnum

  def add(mob, obj) do
    %Mob{mob | inventory: [obj | mob.inventory]}
  end

  def delete(mob, obj) do
    new_inventory = Enum.reject(mob.inventory, &(&1 == obj))
    %Mob{mob | inventory: new_inventory}
  end

  def query(inventory, n \\ 1, phrase) do
    MyEnum.query(inventory, n, phrase)
  end

  def lookup(inventory, id) do
    Enum.find(inventory, &(&1.id == id))
  end

end
