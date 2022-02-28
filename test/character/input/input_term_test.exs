defmodule Mud.Character.Input.InputTermTest do
  use ExUnit.Case

  import Mud.Character.Input.InputTerm

  alias Mud.Test.MockData.ParsedTerm
  alias Mud.Test.MockData.Room

  test "fetch subject" do
    term = ParsedTerm.input_term(:look, subject: 1)
    term = update(term, :subject, :get_subject)
    assert term.subject == Room.mock_mob()
  end

#  test "fetch dobj :self" do
#    term = ParsedTerm.input_term(:look, subject: 1, dobj: :self)
#    term = update(term, :dobj, :get_mob)
#    assert term.dobj == :self
#  end

#  test "fetch dobj" do
#    term = ParsedTerm.input_term(:look, subject: 1, dobj: "beth")
#    term = update(term, :dobj, :get_mob)
#    assert term.dobj == Room.mock_mob2()
#  end


end
