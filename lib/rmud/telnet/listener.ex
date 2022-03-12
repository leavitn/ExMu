defmodule Mud.Telnet.Listener do
  def start_link() do
    IO.puts "Starting Telnet Listener"
    :ranch.start_listener(__MODULE__, :ranch_tcp, [{:port, 4444}], Mud.Telnet.Protocol, [])
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
