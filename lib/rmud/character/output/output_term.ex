defmodule Mud.Character.Output.OutputTerm do
  defstruct [
    :subject, :verb, :dobj, :iobj,
    :state,
    witnesses: [], pattern: []
  ]

  @notify_module Mud.Character

  @type error :: {:error, atom()} | {:error, {atom(), atom()}}
  @type t :: %__MODULE__{} | error

  def new(opts) when is_list(opts), do: struct!(__MODULE__, opts)
  def new(parsed_term), do: struct!(__MODULE__, Map.to_list(parsed_term))

  @doc """
    Similar to Map.update(), but special in that it will return {:error, error} in the event of an error
    Instead of receiving fun, receives a fun_name
      and the function is extrapolated from the input_term.state module
  """
  @spec update(t, atom(), atom()) :: t
  def update({:error, error}, _, _), do: {:error, error}
  def update(term, key, fun_name) when is_atom(fun_name) do
    fun = get_fun(term, fun_name)
    with {:ok, val} <- get!(term, key) |> then(fun), do:
      %{term | key => val}
  end
  def update(term, key, fun) when is_function(fun) do
    Map.update!(term, key, fun)
  end

  @doc "notifies witnesses event occured"
  @spec notify(t, atom(), list()) :: t
  def notify({:error, error}, _, _), do: {:error, error}
  def notify(term, witness, template) do
    term = term |> witnesses(witness) |> Map.replace(:pattern, template)
    IO.inspect term
    output = Map.drop(term, [:witnesses, :state])
    Enum.each(term.witnesses, &@notify_module.notify(&1, output))
  end

  def put({:error, error}, _, _), do: {:error, error}
  def put(term, key, val), do: Map.put(term, key, val)

  def put_and_update(term, key, val, update_fun_name) do
    term
    |> put(key, val)
    |> update(key, update_fun_name)
  end

  @spec witnesses(t, atom()) :: t
  defp witnesses(term, witness) do
    case witness do
      :all -> update(term, :witnesses, :get_mob_ids)
      :subject -> Map.replace(term, :witnesses, subject_id(term) |> List.wrap())
    end
  end

  defp subject_id(%{subject: subject}) do
    case subject do
      %{} -> subject.id
      id -> id
    end
  end

  @spec get!(t, atom()) :: t
  def get!(term, key) do
    case Map.fetch(term, key) do
      {:ok, val} -> val
      :error ->
        error_state = Map.drop(term, [:state, :events, :witnesses, :pattern])
        raise "Key #{key} is missing from input term:\n  #{inspect error_state}"
    end
  end

  # function = <StateModule>.Info.fun_name
  # so if State == Room and fun_name = find_mob, Room.Info.find_mob
  @spec get_fun(t, atom()) :: fun()
  defp get_fun(%{state: state}, fun_name) do
    module = Module.concat(state.__struct__, :Info)
    fn
      :self -> {:ok, :self}
      val -> apply(module, fun_name, [state, val])
    end
  end

end

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

      iex>  Mud.Character.Input.Pattern.run(:dobj)
      [:subject, :verb, :preposition, :dobj, 46]

      iex>  Mud.Character.Input.Pattern.run(:dobj, preposition: "from the", dobj: :dir, punctuation: ?!)
      [:subject, :verb, "from the", :dir, ?!]

      iex>  Mud.Character.Input.Pattern.run(:standard, punctuation: "!!!!")
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
