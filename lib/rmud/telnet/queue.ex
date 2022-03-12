defmodule Mud.Telnet.Queue do
  @moduledoc """
    A queue for telnet input or output.
    Implementation is a wrapper of the erlang :queue module
    Wrapper adds a max capacity to the queue
  """

  defstruct [
    data: :queue.new(),
    capacity: 10,
    count: 0,
    overflow_flag: :clear
  ]

  def new(opts \\ []), do: struct!(__MODULE__, opts)

  def push(queue, item) do
    case queue.count < queue.capacity do
      true -> {:ok, append(queue, item)}
      false -> {:overflow, overflow(queue)}
    end
  end

  defp append(queue, item) do
    %{queue |
        data: :queue.in(item, queue.data),
        count: queue.count + 1
     }
  end

  def pop(queue) do
    case :queue.out(queue.data) do
      {:empty, _} -> {:empty, queue}
      {{:value, term}, new_queue} ->
        new_queue =
          %{queue |
              data: new_queue,
              count: queue.count - 1
          }
        {:ok, term, new_queue}
    end
  end

  defp overflow(queue) do
     case queue.overflow_flag do
       :clear -> new(capacity: queue.capacity) # clear the queue
       :drop -> queue # drop input
       _ -> new(capacity: queue.capacity)
     end
  end

end
