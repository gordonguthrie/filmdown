defmodule Filmdown.Parser do
  @moduledoc """
  Parses filmdown text into semantic HTML.

  Each non-blank line must begin with `IDENTIFIER:: ` where IDENTIFIER is one of
  the supported element types in all caps. Blank lines are silently ignored.
  """

  # Maps filmdown identifiers to {html_tag, css_class}
  @element_map %{
    "SCENEHEADING" => {"h1", "scene-heading"},
    "ACTION" => {"p", "action"},
    "CHARACTER" => {"p", "character"},
    "PARENTHETICAL" => {"p", "parenthetical"},
    "DIALOGUE" => {"p", "dialogue"},
    "TRANSITION" => {"p", "transition"},
    "SHOT" => {"p", "shot"},
    "GENERALTEXT" => {"p", "general-text"},
    "CENTREDGENERALTEXT" => {"p", "centred-general-text"}
  }

  @doc """
  Parses a filmdown string and returns a semantic HTML document string.

  Blank lines in the input are ignored. Lines with an unrecognised identifier
  are also ignored.
  """
  @spec parse(String.t()) :: String.t()
  def parse(filmdown_text) do
    body =
      filmdown_text
      |> String.split("\n")
      |> Enum.reject(&blank_line?/1)
      |> Enum.flat_map(&parse_line/1)
      |> Enum.join("\n")

    "<html><body>\n#{body}\n</body></html>"
  end

  # Returns true when the line is empty or whitespace-only.
  defp blank_line?(line), do: String.trim(line) == ""

  # Parses a single line into a list with zero or one HTML element string.
  defp parse_line(line) do
    case String.split(line, "::", parts: 2) do
      [identifier, content] ->
        identifier = String.trim(identifier)
        content = String.trim(content)

        case Map.get(@element_map, identifier) do
          {tag, class} ->
            escaped = html_escape(content)
            ["<#{tag} class=\"#{class}\">#{escaped}</#{tag}>"]

          nil ->
            []
        end

      _ ->
        []
    end
  end

  # Escapes the characters that are unsafe inside HTML text content.
  defp html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
