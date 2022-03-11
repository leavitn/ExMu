defmodule Mud.World.MobSupervisor do

  alias Mud.Character

  use DynamicSupervisor

  def start_link(zone_id) do
    IO.puts "starting Mob Supervisor"
    DynamicSupervisor.start_link(__MODULE__, [], name: via_tuple(zone_id))
  end

  def via_tuple(zone_id) do
    Mud.Registry.via_tuple({__MODULE__, zone_id})
  end

  def start_child(zone_id, opts) do
    DynamicSupervisor.start_child(via_tuple(zone_id), {Character, opts})
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def child_spec(zone_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [zone_id]},
      type: :supervisor
    }
  end
end
