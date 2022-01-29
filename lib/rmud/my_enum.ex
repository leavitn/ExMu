defmodule Mud.MyEnum do
  @moduledoc "a library of Enum-like functions"

  @doc "ignores the first n - 1 matches"
  def query(list, n, phrase) do
    find_nth(list, n, fn obj ->
      Enum.any?(get_search_data(obj), &(&1 == phrase))
    end)
  end

  defp get_search_data(obj) do
    case obj do
      %{name: name, noun: nil, aliases: aliases} -> [name | aliases]
      %{name: nil, noun: noun, aliases: aliases} -> [noun | aliases]
      %{name: name, noun: noun, aliases: aliases} -> [name, noun | aliases]
      %{keyword: keyword} -> [keyword]
    end
  end

  @doc "like Enum.find, except ignores the first n - 1 results"
  def find_nth(list, n, fun) when n < 2, do: Enum.find(list, fun)
  def find_nth([], _, _), do: nil
  def find_nth([h | t], n, fun) do
    if fun.(h),
    do: find_nth(t, n - 1, fun),
    else: find_nth(t, n, fun)
  end

  @doc "like Enum.reject except it only rejects the first n matches in the list"
  def reject_n([], _, _), do: []
  def reject_n([h | t], n, fun) when n > 0 do
    case fun.(h) do
      true -> reject_n(t, n - 1, fun)
     false -> [h | reject_n(t, n, fun)]
    end
  end
  def reject_n(list, _, _), do: list

  @doc "Like Enum.each except it quits after first truthy result"
  def short_circuit([], _), do: nil
  def short_circuit([h | t], fun), do: fun.(h) || short_circuit(t, fun)

  @doc "given a map and a keyword list, add the contents of the keyword list to the map"
  def list_to_map(map, list) do
    Enum.reduce(list, map, fn {key, val}, map ->
      Map.put(map, key, val)
    end)
  end
end
