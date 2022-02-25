defmodule Mud.Registry do
  def start_link() do
    IO.puts "starting Registry"
    Registry.start_link(name: __MODULE__, keys: :unique)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def alive?({:via, Registry, key}), do: alive?(key)
  def alive?(key), do: Registry.lookup(__MODULE__, key) != []

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
