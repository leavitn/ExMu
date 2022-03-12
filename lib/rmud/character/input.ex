defmodule Mud.Character.Input do

  @moduledoc """
    Module for generically matching a parsed_term to a command and executing them.
    Actual commands are located in the Callback.Commands module
  """

  def run(callback, state, parsed_term) do
    with {:ok, fun} <- get_verb_fun(callback, state, parsed_term.verb), do:
      fun.(parsed_term)
  end

  # Recieves a verb and returns either the corresponding command function OR error
  #    if the verb cannot be performed in the room
  defp get_verb_fun(callback, state, verb) do
    commands = Module.concat(callback, Commands)
    case commands.exist?(verb) do
      true -> {:ok, &apply(commands, verb, [state, &1])}
      false -> {:error, {:command, :not_found}}
    end
  end

end
