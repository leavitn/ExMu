defmodule Mud.Character.Parser.Primatives do

  # takes all words until keyword is encountered
  def until(keyword) do
    many(
      token(except(keyword))
    )
  end

  def except(keywords) when is_list(keywords) do
    word()
    |> satisfy(fn term -> Enum.all?(keywords, &(to_string(&1) != term))
         end)
  end
  def except(keyword), do: List.wrap(keyword) |> except()

  def take_all() do
    fn input ->
      {:ok, input, ""}
    end
  end

  def rest() do
    sequence([
      word(),
      many(sequence([white_space(), word()]))
    ])
    |> map(fn [first | rest] ->
           [first | Enum.map(rest, fn [_, item] -> item end)]
    end)
  end

  def word_cannot_be(keywords) do # accepts any word that is not keyword
    word()
    |> satisfy(fn term -> Enum.any?(keywords, &term != to_string(&1))
       end)
  end

  # either parsers succeed or [] is returned
  def optional(parser) do
    choice([parser, always_succeed()])
  end

  def lazy(combinator) do
    fn input ->
      parser = combinator
      parser.(input)
   end
  end

  def verb(element) do
    keyword(element)
    |> map(fn x -> {:verb, x} end)
  end

  def iobj(parser) do
    parser
    |> map(&rmv_articles/1)
    |> map(fn x -> {:iobj, x} end)
  end

  def dobj(parser) do
    parser
    |> map(&rmv_articles/1)
    |> map(fn x -> {:dobj, x} end)
  end

  def rmv_articles(list) do
    article? = fn
      x when x in ["a", "an", "the"] -> true
      _ -> false
    end
    Enum.reject(list, article?)
  end

  def phrase() do
    many(word())
  end

  def word() do
    token(identifier())
  end

  def comma_list() do
    separated_list(token(identifier()), char(?,))
  end

  def separated_list(element_parser, separator_parser) do
    sequence([
      element_parser,
      many(sequence([separator_parser, element_parser]))
    ])
    |> satisfy(fn             # satisfy that there is more than one element in the list
         [_, []] -> false
         _ -> true
      end)
    |> map(fn [first, rest] ->
           [first | Enum.map(rest, fn [_, item] -> item end)]
    end)
  end

  def error(parser, message) do
    fn input ->
      with {:error, _} <- parser.(input),
        do: {:error, message}
    end
  end

  def keyword(element) do
    token(identifier())
    |> satisfy(fn term -> term == to_string(element) end)
    |> map(fn _ -> element end)
  end

  def token(parser) do
    sequence([
      white_space(),
      parser,
      white_space()
   ])
   |> map(fn [_, term, _] -> term end)
  end

  def identifier() do
    many(identifier_char())
    |> satisfy(fn term -> term != [] end)
    |> map(fn chars -> to_string(chars) end)
  end

  def white_space() do
    # returns either a list of white space or an empty list if no white space
    many(white_space_char())
  end

  def white_space_char(), do: choice([char(?\s), char(?\n), char(?\r), char(?\d), char(?\t)])

  def map(parser, mapper) do
    fn input ->
      with {:ok, term, rest} <- parser.(input),
           do: {:ok, mapper.(term), rest}
    end
  end

  def sequence(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:ok, [], input}
        [first_parser | other_parsers] ->
          with {:ok, first_term, rest} <- first_parser.(input),
               {:ok, other_terms, rest} <- sequence(other_parsers).(rest),
                do: {:ok, [first_term | other_terms], rest}
      end
    end
  end

  def many(parser) do
    fn input ->
      case parser.(input) do
        {:error, _reason} -> {:ok, [], input}
        {:ok, first_term, rest} ->
          {:ok, other_terms, rest} = many(parser).(rest)
          {:ok, [first_term | other_terms], rest}
      end
    end
  end

  def always_succeed() do
    fn input -> {:ok, [], input} end
  end

  def identifier_char() do
    choice([alpha(), char(?_), digit()])
  end

  # like choice but for a nested list
  # fail through each list of parsers
  def choices(parser_lists) do
    case parser_lists do
      [] -> {:error, "no parsers accepted"}
      [parser_list | other_parser_lists] -> with {:error, _reason} <- choice(parser_list),
                                                 do: choices(other_parser_lists)
    end
  end

  def choice(parsers) do
    fn input ->
      case parsers do
        [] -> {:error, "no parsers accepted"}
        [parser | other_parsers] -> with {:error, _reason} <- parser.(input),
                                         do: choice(other_parsers).(input)
      end
    end
  end

  def char(expected), do: satisfy(char(), fn char -> char == expected end)
  def digit(), do: satisfy(char(), fn char -> char in ?0..?9 end)
  def alpha(), do: satisfy(char(), fn char -> char in ?a..?z or char in ?A..?Z end)

  def satisfy(parser, acceptor) do
    fn input ->
      with {:ok, term, rest} <- parser.(input),
        do: if acceptor.(term), do: {:ok, term, rest},
        else: {:error, "acceptor failed"}
    end
  end

  def char() do
    fn input ->
      case input do
        "" -> {:error, "empty string"}
        <<char::utf8, rest::binary>>  -> {:ok, char, rest}
      end
    end
  end
end
