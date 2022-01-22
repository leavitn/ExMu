defmodule Mud.World.ZoneSupervisor do
  alias Mud.World.{RoomSupervisor, Zone}
  alias Mud.Registry

  use Supervisor

  def start_link(zone_id) do
    IO.puts "starting Zone Supervisor for zone #{zone_id}"
    Supervisor.start_link(__MODULE__, zone_id, name: via_tuple(zone_id))
  end

  def via_tuple(zone_id) do
    Registry.via_tuple({__MODULE__, zone_id})
  end

  @impl true
  def init(zone_id) do
    children = [
      {RoomSupervisor, zone_id},
      {Zone, zone_id}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec(zone_id) do
    %{
      id: {__MODULE__, zone_id},
      start: {__MODULE__, :start_link, [zone_id]},
      type: :supervisor
    }
  end
end
