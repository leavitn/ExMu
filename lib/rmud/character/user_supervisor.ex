defmodule Mud.Character.UserSupervisor do

  alias Mud.Character

  def start_link() do
    IO.puts "starting User Supervisor"
    DynamicSupervisor.start_link([
      name: __MODULE__,
      strategy: :one_for_one
    ])
  end

  def start_user(opts) do
    DynamicSupervisor.start_child(__MODULE__, {Character, opts})
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
