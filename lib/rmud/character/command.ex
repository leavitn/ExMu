defmodule Mud.Character.Command do

  def handle_input(module, state, parsed_term) do
    with {:ok, fun} <- get_verb_fun(module, state, parsed_term.verb), do:
      fun.(parsed_term)
  end

  # Recieves a verb and returns either the corresponding command function OR error
  #    if the verb cannot be performed in the room
  defp get_verb_fun(module, state, verb) do
    commands = Module.concat(module, Commands)
    case commands.validate(verb) do
      true -> {:ok, &apply(commands, verb, [state, &1])}
      false -> {:error, {:command, :not_found}}
    end
  end

end
