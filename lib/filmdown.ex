defmodule Filmdown do
  @moduledoc """
  Filmdown is a markdown-inspired markup language for film scripts.

  Each line of a document begins with `IDENTIFIER:: ` where IDENTIFIER is the
  element type in all caps. Blank lines are treated as null.

  Supported element types:
  - `SCENEHEADING`
  - `ACTION`
  - `CHARACTER`
  - `PARENTHETICAL`
  - `DIALOGUE`
  - `TRANSITION`
  - `SHOT`
  - `GENERALTEXT`
  - `CENTREDGENERALTEXT`
  """

  @doc """
  Parses a filmdown string into semantic HTML.

  ## Examples

      iex> Filmdown.to_html("SCENEHEADING:: INT. OFFICE - DAY")
      "<html><body>\\n<h1 class=\\"scene-heading\\">INT. OFFICE - DAY</h1>\\n</body></html>"

  """
  defdelegate to_html(filmdown_text), to: Filmdown.Parser, as: :parse

  @doc """
  Walks a semantic HTML string produced by `to_html/1` and regenerates filmdown.

  ## Examples

      iex> html = Filmdown.to_html("ACTION:: A quiet room.")
      iex> Filmdown.to_filmdown(html)
      "ACTION:: A quiet room."

  """
  defdelegate to_filmdown(html), to: Filmdown.Walker, as: :walk
end
