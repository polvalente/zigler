defmodule Zig.Analyzer do
  @moduledoc """
  tools to analyze AST generated by Zig.Parser
  """

  def info_for(parser_output, symbol) do
    # TODO: cache info_for results.
    path = String.split(symbol, ".")
    find(parser_output.code, path)
  end

  def find(ast, [head | rest]) do
    Enum.find(ast, fn
      {:const, _, {name, _, _}} ->
        name_str = Atom.to_string(name)
        case {head == name_str, rest} do
          {true, []} -> true
          {true, _} ->
            find(ast, rest)
          _ -> nil
        end
      {:fn, _, parts} when rest == [] ->
        if name = parts[:name] do
          Atom.to_string(name) == head
        end
      _ -> nil
    end)
  end

  def translate_location(parsed, file, line) do
    location_search(parsed.comments, line, nil) || {file, line}
  end

  defp location_search([{_, %{line: this_line}} | _], line, last)
    when this_line > line, do: last

  defp location_search([{" ref " <> ref, %{line: this_line}} | rest], line, _) do
    [file, lineoffset] = String.split(ref, ":")
    target_line = line - this_line + String.to_integer(lineoffset)
    location_search(rest, line, {file, target_line})
  end

  defp location_search([_ | rest], line, last), do: location_search(rest, line, last)

  defp location_search([], _, last), do: last
end
