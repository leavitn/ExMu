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

defmodule Mud.Character.Info do

  def get_verb_fun(char, verb) do
    alias Mud.Character.Commands
    case Commands.validate(verb) do
      true -> {:ok, &apply(Commands, verb, [char, &1])}
      false -> {:error, {:command, :not_found}}
    end
  end

end

defmodule Mud.Character.Commands do
  alias Mud.World.Room.Info

  @commands %{
    dump: true
  }

  def validate(verb), do: Map.get(@commands, verb, false)

  def dump(state, _term) do
    IO.inspect state
    :ok
  end

end

defmodule Mud.Character.Private do
  alias Mud.Character.Info

  def handle_input(char, parsed_term) do
    with {:ok, fun} <- Info.get_verb_fun(char, parsed_term.verb), do:
      fun.(parsed_term)
  end

end

defmodule Mud.Character do
  defstruct [:id, :template_id, :room_id, :public, :private]
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
  def handle_cast({:input, term}, state) do
    state =
      case __MODULE__.Private.handle_input(state, term) do
        :ok -> state
        {:ok, state} -> state
        {:error, error} ->
          IO.inspect error #TODO send to connection process or notify AI
          state
      end
    {:noreply, state}
  end
end
