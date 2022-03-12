defmodule Mud.Telnet.Protocol.Private.InputData do
  defstruct [
    last_activity: System.os_time(:millisecond),
    queue: Mud.Telnet.Queue.new()
  ]
end

defmodule Mud.Telnet.Protocol.Private do
  alias Mud.Telnet.Protocol.Reception

  defstruct [
    :socket, :transport, :user,
    input: struct!(__MODULE__.InputData),
    mode: Reception,
    sub_mode: :username
  ]
end

defmodule Mud.Telnet.Protocol do
  @moduledoc """
    TCP/IP user connection
    If this process crashes, user is disconnected
    input and output are handled by mode, which correspond to a Protocol.__mode__
    e.g. Reception mode handles incoming connections
         Main mode is the primary mode used for most connections

    The protocol allows the app "to speak" TCP/IP
  """

  use GenServer

  @behaviour :ranch_protocol

  alias Mud.Telnet.Queue

  @pulse 250 # enforced delay between commands in milliseconds

  #rfc854 Telnet commands
  @iac 255 # Interpret as command
  @ga 249 # Go ahead

  # interpret as command
  @go_ahead <<@iac, @ga>>

  # start_link is called for each new connection
  def start_link(ref, _socket, transport, opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  def push(connection, data) do
    send(connection, {:push, data})
  end

  # implementation functions

  def init(_), do: nil # added here to avoid warning, dead code

  def init(ref, transport, _options) do # init here instead
    IO.puts "Starting connection"

    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    state = struct!(__MODULE__.Private, socket: socket, transport: transport)

    __MODULE__.Reception.greetings(state) # send greetings and option negotiation
    :gen_server.enter_loop(__MODULE__, [], state)
  end

  # input received is handed off to the mode to handle
  # e.g. Reception mode will handle new connections
  #      Main mode is the primary mode users interact with the app

  def handle_info({:tcp, _socket, input}, state) do
    mode = state.mode
    state =
      case mode.parse(input) do # convert binary to parsed_term
        {:error, error} ->
          mode.output({:error, error}, state)
          state
        {:ok, parsed_term, _} ->
          schedule(parsed_term, state)
      end
    {:noreply, state}
  end

  # output is transformed by the mode

  def handle_info({:push, output}, state) do
    mode = state.mode
    mode.output(output, state)
    {:noreply, state}
  end

  # terminate connection

  def handle_info({:tcp_closed, socket}, state = %{transport: transport, user: name}) do
    IO.puts "terminating #{name}'s connection"
    #Mud.Character.Supervisor.terminate_child(name)
    transport.close(socket)
    {:stop, :normal, state}
  end

  @doc """
    If command was delayed and stored in the input queue,
    now it will be consumed.
  """
  def handle_info({:pop, {:input, :queue}}, state) do
    state =
      case Queue.pop(state.input.queue) do
        {:ok, parsed_term, queue} ->
          state = put_in(state.input.queue, queue)
          state.mode.process(parsed_term, state)
        {:empty, _queue} -> state
      end
    {:noreply, state}
  end

  # The mode will ultimately use these output functions
  #   to send data to the connection

  def output({:error, error}, state) do
    error = error_to_string(error)
    output(["Error: ", error], state)
  end
  def output(output, state) do
    render = IO.iodata_to_binary([output, "\r\n", @go_ahead])
    state.transport.send(state.socket, render)
  end

  #TODO interpret errors to provide better feedback
  # e.g. instead of :command :not_found -> "Command not found."
  defp error_to_string(error) when is_atom(error) do
    cond do
      is_atom(error) -> to_string(error)
      is_tuple(error) -> "#{inspect error}"
    end
  end

  # decide whether to process user input (converted to parsed_term) now or later
  # Consecutive commands can fire off no faster than @pulse
  defp schedule(parsed_term, state) do
    timestamp = System.os_time(:millisecond)
    last_activity = state.input.last_activity
    state = put_in(state.input.last_activity, timestamp)
    case timestamp - last_activity do
      x when x < @pulse -> delay(parsed_term, state, @pulse - x)
      _ -> state.mode.process(parsed_term, state)
    end
  end

  # delay the input or notify user rate limit exceeded
  # this occurs when input rate exceeds speed limit defined by @pulse
  defp delay(parsed_term, state, delay_time) do
    {result, queue} = Queue.push(state.input.queue, parsed_term)
    state = put_in(state.input.queue, queue)
    case result do
      :ok -> Process.send_after(self(), {:pop, {:input, :queue}}, delay_time)
      :overflow -> output("Input rate limit exceeded!", state)
    end
    state
  end

end
