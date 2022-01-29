defmodule Mud.World.RoomServer do
  alias Mud.{Registry, Repo}
  alias Mud.World.{Room, Event, Zone}

  use GenServer

  def start_link(id) do
    IO.puts("starting room #{inspect id}")
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def via_tuple(id), do: Registry.via_tuple({__MODULE__, id})

  def alive?(id), do: Registry.alive?({__MODULE__, id})

  def event(id, {status, _} = event) do
    pid = via_tuple(id)
    case status do
      x when x in [:init, :reject] -> GenServer.cast(pid, {:event, event})
      x when x in [:request, :commit] -> GenServer.call(pid, {:event, event})
    end
  end

  def event(event) do
    cond do
      event.to_room == event.from_room ->
        raise "Room events to the same room not yet supported" #TODO
      true ->
        Zone.event(event)
    end
  end

  def operation(id, data) do
    GenServer.cast(via_tuple(id), {:operation, data})
  end

  def get(id) do
    GenServer.call(via_tuple(id), :get)
  end

  def input(id, input) do
    GenServer.cast(via_tuple(id), {:input, input})
  end

  # implementation functions

  @impl true
  def init(id) do
    {:ok, id, {:continue, :get_room}}
  end

  @impl true
  def handle_continue(:get_room, id) do
    {:noreply, Repo.room(id)}
  end

  @impl true
  def handle_cast({:operation, data}, state) do
    {:noreply, apply(data.module, data.fun, [state | data.args])}
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
    {:noreply, module.process(event, state)}
  end

  @impl true
  def handle_call({:event, event}, _, state) do
    module = Module.concat(Room, Event.module(event))
    {reply, state} = module.process(event, state)
    {:reply, reply, state}
  end

  @impl true
  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

end
