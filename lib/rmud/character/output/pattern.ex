defmodule Mud.Character.Output.Pattern do
  @doc """
    returns output pattern templates
    Each part of the template will reference a key in the request map
      which the output module will then process into IO data
    Options will replace parts of the template for customizations

    patterns:
      :standard -> [:subject, :verb, :dobj, ?.]
      :iobj-> [:subject, :verb, :dobj, :preposition, :iobj, ?.]
      :dobj -> [:subject, :verb, :preposition, :dobj, ?.]

    ## Examples

      iex> Mud.Character.Output.OutputTerm.Pattern.run(:dobj)
      [:subject, :verb, :preposition, :dobj, 46]

      iex> Mud.Character.Output.OutputTerm.Pattern.run(:dobj, preposition: "from the", dobj: :dir, punctuation: ?!)
      [:subject, :verb, "from the", :dir, ?!]

      iex> Mud.Character.Output.OutputTerm.Pattern.run(:standard, punctuation: "!!!!")
      [:subject, :verb, :dobj, "!!!!"]
  """
  def run(pattern, opts \\ [])
  def run(pattern, []), do: _run(pattern)
  def run(pattern, opts) do
    # TODO convert to macro
    Enum.map(_run(pattern), fn item ->
      Enum.find_value(opts, item, fn
          {:punctuation, val} -> if ?. == item, do: val
          {key, val} -> if key == item, do: val
      end)
    end)
  end

  defp _run(pattern) do
    case pattern do
      :standard -> [:subject, :verb, :dobj, ?.]
      :iobj-> [:subject, :verb, :dobj, :preposition, :iobj, ?.]
      :dobj -> [:subject, :verb, :preposition, :dobj, ?.]
      :intransitive_dir -> [:dobj, :verb, :dir, ?.]
    end
  end
end
