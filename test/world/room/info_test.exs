defmodule Mud.World.Room.InfoTest do
  use ExUnit.Case

  import Mud.World.Room.Info

  alias Mud.World.Room
  alias Room.{Content, Exit}

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

  test "get mob" do
    mock_data = mock_data()
    {:ok, result1} = mock_data |> get_mob("orc")
    {:ok, result2} = mock_data |> get_mob("captain")
    {:ok, result3} = mock_data |> get_mob("orc captain")
    {same, same, same} = {result1, result2, result3}
    assert same == mock_mob()
    {:error, error} = mock_data |> get_mob("flower")
    assert error == {:mob, :not_found}
  end

  test "get exit" do
    south = struct!(Exit, keyword: :south, from_room: 1, to_room: 2)
    case mock_data() |> get_exit(:south) do
      {:ok, ^south} -> assert true
      {:error, {:exit, :not_found}} -> assert false
    end
    case mock_data() |> get_exit(:north) do
      {:error, {:exit, :not_found}} -> assert true
      {:ok, _north} -> assert false
    end
  end

  test "get subject" do
    mock_data = mock_data()
    {:ok, result} = mock_data |> get_subject(1)
    {:error, error} = mock_data |> get_subject(2)
    assert result == mock_mob()
    assert error == {:subject, :not_found}
  end

  test "get any" do
    mock_data = mock_data()
    {:ok, result1} = mock_data |> get_any("orc")
    {:ok, result2} = mock_data |> get_any("captain")
    {:ok, result3} = mock_data |> get_any("orc captain")
    {same, same, same} = {result1, result2, result3}
    assert same == mock_mob()
    {:error, error} = mock_data |> get_any("error")
    assert error == :not_found
  end

  test "get exit to room" do
    case mock_data() |> get_exit_to_room(:south) do
      {:ok, 2} -> assert true
      {:error, {:exit, :not_found}} -> assert false
    end
    case mock_data() |> get_exit_to_room(:north) do
      {:error, {:exit, :not_found}} -> assert true
      {:ok, _north} -> assert false
    end
  end
end
