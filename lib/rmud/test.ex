defmodule Mud.Test.MockData.Room do

  alias Mud.World.Room
  alias Room.{Exit, Content}

  def mock_data() do
    mock_room()
    |> Content.create(mock_mob())
    |> Content.create(mock_mob2())
  end

  def mock_room() do
    south = struct!(Exit, keyword: :south, from_room: 1, to_room: 2)
    struct!(Room, name: "North Room", exits: %{south: south}, id: 1)
  end

  def mock_mob() do
    args = [
      id: 1,
      short_desc: "orc captain",
      aliases: ["orc", "captain"]
    ]
    struct!(Content.Mob, args)
  end

  def mock_mob2() do
    args = [
      id: 2,
      short_desc: "beth"
    ]
    struct!(Content.Mob, args)
  end
end

defmodule Mud.Test.MockData.ParsedTerm do
  alias Mud.Test.MockData
  alias Mud.MyEnum
  alias Mud.Character.Output.OutputTerm

  def output_term(verb, opts) do
    mock_room = MockData.Room.mock_data()
    parsed_term = %{
      verb: verb,
      state: mock_room,
    }
    MyEnum.list_to_map(parsed_term, opts)
    |> OutputTerm.new()
  end
end
