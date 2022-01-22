defmodule Mud do
  alias Mud.World
  def start() do
    children = [
      Mud.Registry,
      {World, 0}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
