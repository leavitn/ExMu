defmodule Mud.Character.Output.OutputTermTest do
  use ExUnit.Case

  import Mud.Character.Output.OutputTerm

  alias Mud.Test.MockData.ParsedTerm
  alias Mud.Test.MockData.Room

  test "update subject" do
    term = ParsedTerm.output_term(:look, subject: 1)
    term = update(term, :subject, :find_id)
    assert term.subject == Room.mock_mob()
  end

  test "update dobj :self" do
    term = ParsedTerm.output_term(:look, subject: 1, dobj: :self)
    term = update(term, :dobj, :find_mob)
    assert term.dobj == :self
  end

  test "update dobj" do
    term = ParsedTerm.output_term(:look, subject: 1, dobj: "beth")
    term = update(term, :dobj, :find_mob)
    assert term.dobj == Room.mock_mob2()
  end

end
