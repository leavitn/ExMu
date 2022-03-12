defmodule Mud.Telnet.Protocol.Main do
  @moduledoc """
    main mode for I/O
  """
  alias Mud.Telnet.{Protocol}
  alias Mud.Character

  def output(output, state), do: Protocol.output(output, state)

  def parse(data) do
    case data do
      "dump\r\n" -> {:ok, %{verb: :dump}, []} # temporary - for testing purposes
      _ -> Character.Parser.process(data)
    end
  end

  def process(parsed_term, state) do
    Character.input(state.user, parsed_term)
    state
  end

end
