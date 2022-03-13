defmodule Mud.Character.Output.Spaces do
  # insert a space character \s between members of a list
  defmacro spaces(list) do
    quote do
      unquote add_spaces(list)
    end
  end

  defguardp is_punctuation(c) when c in [?., ?!, ??]

# like Enum.intersperse(?\s) EXCEPT
#   doesn't put a space between the last word and punctuation
  def add_spaces([]), do: []
  def add_spaces([h, x]) when is_punctuation(x), do: [h, x] # punctuation
  def add_spaces([h]), do: [h | add_spaces([])]
  def add_spaces([h | t]), do: [h, ?\s | add_spaces(t)]
end

defmodule Mud.Character.Output do
  @doc """
    Render text is not dynamically generated on the fly subjectively for each witness.
    Instead it represents a single objective representation of the object to all witnesses in the room.
    This was elected for simplicity.
  """

  alias Mud.Character.Output.OutputTerm
  import __MODULE__.Spaces

  def process(term, witness), do: process(term, term.pattern, witness)
  def process(term, pattern, witness)
    when is_list(pattern), do: replace(term, pattern, witness)
  def process(term, pattern, witness)
    when is_atom(pattern), do: build(term, pattern, witness)
#  def process(term, pattern, _ )
#    when is_atom(pattern), do: template(input_term, pattern)

  defp replace(term, pattern, witness) do
    Enum.map(pattern, fn
      :verb -> conjugate(term.verb, term.subject.id, witness)
      key when is_atom(key) -> extract_and_transform(term, key)
      no_change -> no_change
    end)
    |> add_spaces()
  end

  defp conjugate(verb, subject, witness)
    when is_atom(verb), do: conjugate(to_string(verb), subject, witness)
  defp conjugate(verb, same, same), do: verb
  defp conjugate(verb, _, _), do: [verb, ?s]

  defp extract_and_transform(term, key) do
    case OutputTerm.get!(term, key) do
      x when is_atom(x) -> to_string(x)
      x when is_map(x) -> Map.get(x, :short_desc)
    end
  end

  defp build(term, template, _witness) do
    case template do
      :room -> __MODULE__.Template.room(term)
    end
  end

end
