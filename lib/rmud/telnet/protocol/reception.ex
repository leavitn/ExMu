defmodule Mud.Telnet.Protocol.Reception do
  @moduledoc """
    Reception state for a connection
    i.e. greetings screen, login
    if new character, hand over to nanny, else hand over to the main module
  """

  alias Mud.{Telnet.Protocol, Character}

  def greetings(state) do
    greetings = "\u001b[0mEnter user name: "
    output(greetings, state)
  end

  def parse(input) do
    {:ok, rmv_trailing(input, "\r\n"), []}
  end

  def process(input, state) do
    # all functions here must return state
    case state.sub_mode do
      :username -> check_username(input, state)
    end
  end

  def output(output, state), do: Protocol.output(output, state)

  defp check_username(name, state) do
    case name do
      _ -> login(name, state)
    end
  end

  defp login(name, state) do
    opts = %{id: name, connection: self(), template_id: name, room_id: {1,1,1}}
    case Character.UserSupervisor.start_user(opts) do
      {:error, {:already_started, _pid}} ->
        output("Error: already logged in. Please submit a new name: ", state)
        state
      {:ok, _pid} ->
         output("Welcome #{name}", state)
         %{state |
            user: name,
            mode: Protocol.Main,
            sub_mode: :default
          }
    end
  end

  defp rmv_trailing(string, tail) do
    n = byte_size(string) - byte_size(tail)
    << head::binary-size(n), _::binary >> = string
    head
  end
end
