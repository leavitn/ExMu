# Saves:
#   [:inventory, :description, :stats, :commands]
# module will parse commands into parsed_terms and process those parsed terms if the
# player has the commands
# Info based commands never hit the room:
#   :score, :inventory, :help, :channel chat (not room chat)
# Physical actions (combat, say, get/drop/look (other than self)).
# receive result of actions from rooms
# room will contain aliases, h/m/v stats for combat
# Score won't show h/m/v stats, you'll get that enough from the prompt

defmodule Mud.Character.Commands do

  # to add commands that run out of the character process
  #   1. Add verb to @commands
  #   2. add command function

  # character command verbs must be added here to be valid
  @commands %{
    dump: true, # testing only - remove from prod
    look: true,
    go: true
  }

  alias Mud.World.RoomServer

  def exist?(verb), do: Map.get(@commands, verb, false)

  def dump(state, _term) do
    IO.inspect state
    :ok
  end

  def look(state, term) do
    case term.dobj do
      :room -> to_room(state.room_id, term)
    end
  end

  # Movement occurs in the room, but char process can veto the movement
  # e.g. if the character is sleeping
  def go(state, term) do
    to_room(state.room_id, term)
  end

  defp to_room(room_id, term) do
    term = Map.delete(term, :state)
    RoomServer.input(room_id, term)
  end
end

defmodule Mud.Character do
  defstruct [:id, :template_id, :connection, :room_id, :public, :private]
  alias Mud.{Registry, Repo, World}
  alias World.RoomServer

  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: via_tuple(options.id))
  end

  def via_tuple(id), do: Registry.via_tuple({__MODULE__, id})

  def input(id, parsed_term) do
    GenServer.cast(via_tuple(id), {:input, parsed_term})
  end

  def get(id) do
    GenServer.call(via_tuple(id), :get)
  end

  def notify(id, output) do
    GenServer.cast(via_tuple(id), {:output, output})
  end

  def update_location(char_id, room_id) do
    GenServer.call(via_tuple(char_id), {:location, room_id})
  end

  # implementation functions

  @impl true
  def init(options) do
    {:ok, options, {:continue, :get_data}}
  end

  @impl true
  def handle_continue(:get_data, options) do
    state = struct!(__MODULE__, Map.to_list(options))
    state = Map.put(state, :public, apply(Repo, :mob, [state.template_id]))
    RoomServer.spawn(state.room_id, state.id, :mob, state.template_id)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:location, room_id}, _, state) do
    {:reply, :ok, Map.replace(state, :room_id, room_id)}
  end

  @impl true
  def handle_cast({:input, term}, state) do
    alias Mud.Character.Input
    term = term |> Map.put(:subject, state.id)
    state =
      case Input.run(__MODULE__, state, term) do
        :ok -> state
        {:ok, state} -> state
        {:error, error} ->
          IO.inspect error #TODO send to connection process or notify AI
          state
      end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:output, term}, state) do
    alias Mud.Telnet.Protocol
    alias Mud.Character.Output

    case state.connection do
      nil -> nil
      connection -> Protocol.push(connection, Output.process(term, state.id))
    end

    {:noreply, state}
  end

end
