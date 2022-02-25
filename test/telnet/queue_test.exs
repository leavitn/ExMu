defmodule Mud.Telnet.QueueTest do
  use ExUnit.Case
  alias Mud.Telnet.Queue
  import Mud.Telnet.Queue

  test "pop test" do
    {:ok, queue} = struct!(Queue) |> push(:one)
    {:ok, queue} = push(queue, :two)
    {:ok, queue} = push(queue, :three)
    {:ok, val1, queue} = pop(queue)
    {:ok, val2, queue} = pop(queue)
    {:ok, val3, queue} = pop(queue)
    {val4, _} = pop(queue)
    assert val1 == :one
    assert val2 == :two
    assert val3 == :three
    assert val4 == :empty
  end

  test "empty test" do
    {val, _} = struct!(Queue) |> pop()
    assert val == :empty
    {:ok, queue} = struct!(Queue) |> push(:one)
    {:ok, _, queue} = pop(queue)
    {val, _} = pop(queue)
    assert val == :empty
  end

  test "overflow test" do
    {:ok, queue} =
      struct!(Queue, capacity: 2, overflow_flag: :clear)
      |> push(:one)
    {:ok, queue} = push(queue, :two)
    {error, queue} = push(queue, :three)
    assert error == :overflow
    assert queue == struct!(Queue, capacity: 2, overflow_flag: :clear)
  end

  test "count test" do
    queue = struct!(Queue)
    assert queue.count == 0
    {:ok, queue} = push(queue, :one)
    assert queue.count == 1
    {:ok, queue} = push(queue, :two)
    assert queue.count == 2
    {:ok, queue} = push(queue, :three)
    assert queue.count == 3
    {:ok, _, queue} = pop(queue)
    assert queue.count == 2
    {:ok, _, queue} = pop(queue)
    assert queue.count == 1
  end

end
