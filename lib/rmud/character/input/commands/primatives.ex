defmodule Mud.Character.Input.Commands.Primatives do
  alias Mud.World.Room

  @moduledoc """
    This module contains the building blocks for constructing commands
  """

  def get_inquiry(:room), do: :room
  def get_inquiry(_), do: :any

  @doc """
    Replace the val in request for a given key with the result of a query
    Or return an error
    request = request that will be transformed
    key = key that will have value replaced
    query_type = which list in Room.Content to check
  """
  def fetch(request, :subject), do: fetch(request, :subject, :subject)
  def fetch({:error, error}, _, _), do: {:error, error}
  def fetch(request, key, query_type) do
    state_module = struct_module(request.state)
    with {:ok, data} <- query(state_module, request, key, query_type), do:
      Map.put(request, key, data)
  end

  defp query(module, request, key, query_type) do
    case Map.get(request, key) do
      nil -> raise "#{key} missing from parsed_term"
      :self -> {:ok, :self} # note to output to use subject data in output for this key
      _ -> _query(module, request, key, query_type)
    end
  end

  defp _query(Room, request, key, query_type) do
    alias Room.Info
    %{
      ^key => input,
      state: state
     } = request

    case query_type do
      :subject -> Info.get_subject(state, input)
      :item -> Info.get_item(state, input)
      :mob -> Info.get_mob(state, input)
      :any -> Info.get_any(state, input)
      :room -> {:ok, state}
      :exit -> Info.get_exit(state, input)
      :path -> Info.get_exit_path(state, input)
    end
  end

  #def fetch_inventory({:error, error}, _, _), do: {:error, error}
  #def fetch_inventory(request, input_key, who_key) do
  #  with {:ok, data } <- Info.get_item_from_inv(request[who_key], request[input_key]), do:
  #    %{request | input_key => data}
  #end

  defp struct_module(%{__struct__: module}), do: module

  # given a map, returns an atom representing the structure type
  #defp struct_type(%{__struct__: struct_name}) do
  #  case struct_name do
  #    Room -> :room
  #    Mob -> :mob
  #    Exit -> :exit
  #    _ -> :error
  #  end
  #end

  @doc "adds output pattern / templates to result and list of witnesses"
  def notify(request, witness, template) do
    request
    |> witnesses(witness)
    |> Map.put(:patterns, template)
    |> event()
  end

  defp witnesses(request, filter) do
    case struct_module(request.state) do
      Room -> %{request | witnesses: get_witnesses(request, filter)}
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

      iex> Mud.Character.Input.Commands.Primatives.pattern(:dobj)
      [:subject, :verb, :preposition, :dobj, 46]

      iex> Mud.Character.Input.Commands.Primatives.pattern(:dobj, preposition: "from the", dobj: :dir, punctuation: ?!)
      [:subject, :verb, "from the", :dir, ?!]

      iex> Mud.Character.Input.Commands.Primatives.pattern(:standard, punctuation: "!!!!")
      [:subject, :verb, :dobj, "!!!!"]
  """
  def pattern(pattern, opts \\ [])
  def pattern(pattern, []), do: _pattern(pattern)
  def pattern(pattern, opts) do
    # TODO convert to macro
    Enum.map(_pattern(pattern), fn item ->
      Enum.find_value(opts, item, fn
          {:punctuation, val} -> if ?. == item, do: val
          {key, val} -> if key == item, do: val
      end)
    end)
  end

  defp _pattern(pattern) do
    case pattern do
      :standard -> [:subject, :verb, :dobj, ?.]
      :iobj-> [:subject, :verb, :dobj, :preposition, :iobj, ?.]
      :dobj -> [:subject, :verb, :preposition, :dobj, ?.]
      :intransitive_dir -> [:dobj, :verb, :dir, ?.]
    end
  end

end
