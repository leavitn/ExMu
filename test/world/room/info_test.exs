defmodule Mud.World.Room.InfoTest do
  use ExUnit.Case

  import Mud.World.Room.Info
  import Mud.Test.MockData.Room

  alias Mud.World.Room.Exit

  test "get mob" do
    mock_data = mock_data()
    {:ok, result1} = mock_data |> find_mob("orc")
    {:ok, result2} = mock_data |> find_mob("captain")
    {:ok, result3} = mock_data |> find_mob("orc captain")
    {same, same, same} = {result1, result2, result3}
    assert same == mock_mob()
    {:error, error} = mock_data |> find_mob("flower")
    assert error == {:mob, :not_found}
  end

  test "get exit" do
    south = struct!(Exit, keyword: :south, from_room: 1, to_room: 2)
    case mock_data() |> find_exit(:south) do
      {:ok, ^south} -> assert true
      {:error, {:exit, :not_found}} -> assert false
    end
    case mock_data() |> find_exit(:north) do
      {:error, {:exit, :not_found}} -> assert true
      {:ok, _north} -> assert false
    end
  end

  test "get subject" do
    mock_data = mock_data()
    {:ok, result} = mock_data |> find_subject(1)
    {:error, error} = mock_data |> find_subject(999)
    assert result == mock_mob()
    assert error == {:subject, :not_found}
  end

  test "get any" do
    mock_data = mock_data()
    {:ok, result1} = mock_data |> find_any("orc")
    {:ok, result2} = mock_data |> find_any("captain")
    {:ok, result3} = mock_data |> find_any("orc captain")
    {same, same, same} = {result1, result2, result3}
    assert same == mock_mob()
    {:error, error} = mock_data |> find_any("error")
    assert error == :not_found
  end

  test "get exit to room" do
    case mock_data() |> find_exit_path(:south) do
      {:ok, 2} -> assert true
      {:error, {:exit, :not_found}} -> assert false
    end
    case mock_data() |> find_exit_path(:north) do
      {:error, {:exit, :not_found}} -> assert true
      {:ok, _north} -> assert false
    end
  end

  test "exit keyword lookup" do
    keyword = mock_data() |> exit_keyword_lookup(2, :to_room)
    assert keyword == :south
  end

  test "find command" do
    {:ok, _} = get_verb_fun(mock_data(), :go)
    assert true
  end
end
