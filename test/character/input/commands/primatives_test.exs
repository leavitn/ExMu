defmodule Mud.Character.Input.Commands.PrimativesTest do
  use ExUnit.Case
  doctest Mud.Character.Input.Commands.Primatives

  import Mud.Character.Input.Commands.Primatives

  alias Mud.Test.MockData.ParsedTerm
  alias Mud.Test.MockData.Room

  test "fetch subject" do
    request = ParsedTerm.parsed_term(:look, subject: 1)
    request = fetch(request, :subject)
    assert request.subject == Room.mock_mob()
  end

  test "fetch dobj :self" do
    request = ParsedTerm.parsed_term(:look, subject: 1, dobj: :self)
    request = fetch(request, :dobj, :any)
    assert request.dobj == :self
  end

  test "fetch dobj" do
    request = ParsedTerm.parsed_term(:look, subject: 1, dobj: "beth")
    request = fetch(request, :dobj, :mob)
    assert request.dobj == Room.mock_mob2()
  end


end
