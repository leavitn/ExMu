defmodule Mud.Character.Input.InputTerm do
  defstruct [
    :subject, :verb, :dobj, :iobj,
    :state,
    events: [], witnesses: [], pattern: []
  ]

  def new(parsed_term), do: struct!(__MODULE__, Map.to_list(parsed_term))

  @doc """
    Similar to Map.update(), but special in that it will return {:error, error} in the event of an error
    Instead of receiving fun, receives a fun_name
      and the function is extrapolated from the input_term.state module
  """
  def update({:error, error}, _, _), do: {:error, error}
  def update(term, key, fun_name) do
    fun = get_fun(term, fun_name)

    with {:ok, val} <- get!(term, key) |> then(fun), do:
      %{term | key => val}
  end

  @doc "adds output pattern / templates to result and list of witnesses"
  def notify(request, witness, template) do
    request
    |> Map.replace!(:witnesses, witnesses(request, witness))
    |> Map.replace!(:patterns, template)
    |> event()
  end

  defp get!(input_term, key) do
    case Map.fetch(input_term, key) do
      {:ok, val} -> val
      :error ->
        error_state = Map.drop(input_term, [:state, :events, :witnesses, :pattern])
        raise "Key #{key} is missing from input term:\n  #{inspect error_state}"
    end
  end

  defp get_fun(%{state: state}, fun_name) do
    module = Module.concat(state.__struct__, :Info)
    fn
      val -> apply(module, fun_name, [state, val])
    end
  end

  defp witnesses(term, filter) do
    case term.state.__struct__ do
      Room -> get_witnesses(term, filter)
    end
  end

  defp get_witnesses(request, :all_but_subject), do:
    Room.Info.get_occupants(request.state, {:all_but, request.subject.id})
  defp get_witnesses(%{state: state}, filter), do:
    Room.Info.get_occupants(state, filter)

  # """
  #  transforms request into an event by placing a copy of the current request,
  #    minus the world state, in a list within the request.
  # """
  defp event(request) do
    event = Map.drop(request, [:events, :state])
    %{
      request |
        events: [event | request.events],
        witnesses: [], # reset patterns and witnesses
        pattern: []  # for next event
    }
  end

end
