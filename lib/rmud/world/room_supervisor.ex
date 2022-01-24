defmodule Mud.World.RoomSupervisor do
  alias Mud.Registry
  alias Mud.World.RoomServer

  use DynamicSupervisor

  def start_link(zone_id) do
    DynamicSupervisor.start_link(__MODULE__, zone_id, name: via_tuple(zone_id))
  end

  def via_tuple(zone_id) do
    Registry.via_tuple({__MODULE__, zone_id})
  end

  def start_room(zone_id, id) do
    IO.puts "attempting to start room #{inspect id} in zone #{inspect zone_id}"
    #spec = %{id: {RoomServer, id}, start: {RoomServer, :start_link, [id]}}
    DynamicSupervisor.start_child(via_tuple(zone_id), {RoomServer, id})
  end

  @impl true
  def init(_id) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def child_spec(zone_id) do
    %{
      id: {__MODULE__, zone_id},
      start: {__MODULE__, :start_link, [zone_id]},
      type: :supervisor
    }
  end
end
