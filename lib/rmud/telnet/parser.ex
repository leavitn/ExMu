defmodule Mud.Character.Parser do

  import Mud.Character.Parser.Primatives

  def process(input) do
    parser = master_parser()
    input
    |> String.downcase()
    |> then(parser)
  end

  def master_parser() do
    choice(
      [
        go_statement(),
        chat_statement(),
        look_statement(),
        get_statement(),
        open_statement(),
        close_statement()
      ]
    )
    |> map(fn term -> Enum.into(term, %{}) end)
  end

  def open_statement() do
    sequence([
      verb(:open),
      choice([
        direction_statement(),
        dobj(phrase())
      ])
    ])
  end

  def close_statement() do
    sequence([
      verb(:close),
      choice([
        direction_statement(),
        dobj(phrase())
      ])
    ])
  end

  def look_statement() do
    choice([
      sequence([
        choice([keyword("l"), verb(:look)]),
        choice([
          sequence([keyword(:at), dobj(phrase())]),
          sequence([keyword(:in), dobj(phrase())]),
          dobj(phrase())
        ])
      ]),
      choice([keyword("l"), verb(:look)])
    ])
    |> map(fn
        [_, {:dobj, []}] -> [verb: :look, dobj: :room]
        [_, [:at, dobj]] -> [verb: :look, dobj: dobj]
        term -> term
      end)
  end

  def get_statement() do
    sequence([
      verb(:get),
      dobj(
        until(:from)
      ),
      optional(
        from_statement()
      )
    ])
    |> map(fn
        [verb, dobj, []] -> [verb, dobj]
        term -> term
      end)
  end

  def from_statement() do
    sequence([
      keyword(:from),
        iobj(phrase())
    ])
    |> map(fn [:from, iobj] -> iobj end)
  end

  def go_statement() do
    direction_statement()
    |> map(fn term -> [{:verb, :go}, term] end)
  end

  def direction_statement() do
   choice([
     keyword("n"), keyword("north"),
     keyword("s"), keyword("south"),
     keyword("e"), keyword("east"),
     keyword("w"), keyword("west")
   ])
   |> map(fn term -> {:dobj, direction_to_atom(term)} end)
  end

  def chat_statement do
    sequence([
      choice(
        [
          verb(:say),
          verb(:yell),
          verb(:whisper),
          verb(:ooc)
        ]
      ),
      message()
    ])
  end

  def direction_to_atom(direction) do
    case direction do
      x when x in ["n", "north"] -> :north
      x when x in ["s", "south"] -> :south
      x when x in ["e", "east"] -> :east
      x when x in ["w", "west"] -> :west
      _ -> direction
    end
  end

  def message() do
    take_all()
    |> map(fn term -> {:message, term} end)
  end

end
