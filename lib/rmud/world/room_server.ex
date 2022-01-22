defmodule Mud.World.RoomServer do
  alias Mud.{Registry, Repo}
  alias Mud.World.{Room, Event, Zone}

  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def via_tuple(id), do: Registry.via_tuple({__MODULE__, id})

  def alive?(id), do: Registry.alive?({__MODULE__, id})

  def event(id, {status, _} = event) do
    pid = via_tuple(id)
    case status do
      :reject -> GenServer.cast(pid, {:event, event})
      x when x in [:notify, :commit] -> GenServer.call(pid, {:event, event})
    end
  end

  def event(event) do
    case get_rooms(event) do
      {same, same} -> raise "Room events to the same room not yet supported" #TODO
      _ -> Zone.event(event)
    end
  end

  def input(id, input) do
    GenServer.cast(via_tuple(id), {:input, input})
  end

  defp get_rooms(event) do
    {_, _, to} = event.to_room
    {_, _, from} = event.from_room
    {to, from}
  end

  # implementation functions

  @impl true
  def init(id) do
    {:ok, id, {:continue, :get_room}}
  end

  @impl true
  def handle_continue({:get_room}, id) do
    {:noreply, Repo.room(id)}
  end

  @impl true
  def handle_cast({:input, _parsed_term}, state) do
    #{events, state} = parsed_term |> Commands.process()
    #notify(events)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    module = Module.concat(Room, Event.module(event))
    state = module.process(event)
    {:noreply, state}
  end

  @impl true
  def handle_call({:event, event}, _, state) do
    module = Module.concat(Room, Event.module(event))
    {reply, state} = module.process(event, state)
    {:reply, reply, state}
  end

end
