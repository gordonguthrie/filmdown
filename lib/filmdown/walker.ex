defmodule Filmdown.Walker do
  @moduledoc """
  Walks the semantic HTML produced by `Filmdown.Parser` and regenerates filmdown text.
  """

  # Maps CSS class names back to filmdown identifiers.
  @class_to_identifier %{
    "filmdown-scene-heading" => "SCENEHEADING",
    "filmdown-action" => "ACTION",
    "filmdown-character" => "CHARACTER",
    "filmdown-parenthetical" => "PARENTHETICAL",
    "filmdown-dialogue" => "DIALOGUE",
    "filmdown-transition" => "TRANSITION",
    "filmdown-shot" => "SHOT",
    "filmdown-general-text" => "GENERALTEXT",
    "filmdown-centred-general-text" => "CENTREDGENERALTEXT"
  }

  # Matches a single HTML element produced by the parser, e.g.
  # <p class="action">content here</p>
  @element_pattern ~r/<(\w+)\s+class="([^"]+)">([^<]*)<\/\1>/

  @doc """
  Walks semantic HTML and returns the corresponding filmdown text.

  Only elements whose CSS class is recognised as a filmdown element type are
  included in the output; all other markup (e.g. `<html>`, `<body>`) is ignored.
  Lines are joined with newlines.
  """
  @spec walk(String.t()) :: String.t()
  def walk(html) do
    @element_pattern
    |> Regex.scan(html)
    |> Enum.flat_map(fn [_full, _tag, class, content] ->
      case Map.get(@class_to_identifier, class) do
        nil -> []
        identifier -> ["#{identifier}:: #{html_unescape(content)}"]
      end
    end)
    |> Enum.join("\n")
  end

  # Reverses the HTML escaping applied by the parser.
  # &amp; must be replaced last to avoid double-unescaping.
  defp html_unescape(text) do
    text
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end
end
