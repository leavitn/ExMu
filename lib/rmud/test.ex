defmodule Mud.Test.MockData.Room do

  alias Mud.World.Room
  alias Room.{Exit, Content}

  def mock_data() do
    mock_room()
    |> Content.create(mock_mob())
  end

  def mock_room() do
    south = struct!(Exit, keyword: :south, from_room: 1, to_room: 2)
    struct!(Room, name: "North Room", exits: %{south: south}, id: 1)
  end

  def mock_mob() do
    args = [
      id: 1,
      render_text: "orc captain",
      aliases: ["orc", "captain"]
    ]
    struct!(Content.Mob, args)
  end

  defmodule Mud.Test.MockData.ParsedTerm do
    alias Mud.Test.MockData
    alias Mud.MyEnum

    def parsed_term(verb, opts) do
      %{
        verb: verb,
        state: MockData.Room.mock_data()
      }
      |> MyEnum.list_to_map(opts)
    end
  end
end
