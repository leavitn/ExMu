defmodule Mud.Character.Input.InputTermTest do
  use ExUnit.Case

  import Mud.Character.Input.InputTerm

  alias Mud.Test.MockData.ParsedTerm
  alias Mud.Test.MockData.Room
  alias Mud.Character.Input.Pattern
  alias Mud.Character.Input.InputTerm

  test "update subject" do
    term = ParsedTerm.input_term(:look, subject: 1)
    term = update(term, :subject, :find_subject)
    assert term.subject == Room.mock_mob()
  end

  test "update dobj :self" do
    term = ParsedTerm.input_term(:look, subject: 1, dobj: :self)
    term = update(term, :dobj, :find_mob)
    assert term.dobj == :self
  end

  test "update dobj" do
    term = ParsedTerm.input_term(:look, subject: 1, dobj: "beth")
    term = update(term, :dobj, :find_mob)
    assert term.dobj == Room.mock_mob2()
  end

  test "notify" do
    term =
      ParsedTerm.input_term(:look, subject: 1, dobj: "beth")
      |> update(:subject, :find_subject)
      |> update(:dobj, :find_mob)
      |> notify(:all, Pattern.run(:standard))
    case List.first(term.events) do
      %InputTerm{witnesses: [2, 1]} -> assert true
      _ -> assert false
    end
  end



end
