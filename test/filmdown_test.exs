defmodule FilmdownTest do
  use ExUnit.Case
  doctest Filmdown

  alias Filmdown.Parser
  alias Filmdown.Walker

  # ---------------------------------------------------------------------------
  # Parser tests
  # ---------------------------------------------------------------------------

  describe "Filmdown.Parser.parse/1" do
    test "parses a SCENEHEADING line into an h1" do
      filmdown = "SCENEHEADING:: INT. OFFICE - DAY"
      html = Parser.parse(filmdown)
      assert html =~ ~s{<h1 class="filmdown-scene-heading">INT. OFFICE - DAY</h1>}
    end

    test "parses an ACTION line into a paragraph" do
      filmdown = "ACTION:: A quiet room."
      html = Parser.parse(filmdown)
      assert html =~ ~s{<p class="filmdown-action">A quiet room.</p>}
    end

    test "parses a CHARACTER line" do
      html = Parser.parse("CHARACTER:: JOHN")
      assert html =~ ~s{<p class="filmdown-character">JOHN</p>}
    end

    test "parses a PARENTHETICAL line" do
      html = Parser.parse("PARENTHETICAL:: (nervously)")
      assert html =~ ~s{<p class="filmdown-parenthetical">(nervously)</p>}
    end

    test "parses a DIALOGUE line" do
      html = Parser.parse("DIALOGUE:: Hello, world.")
      assert html =~ ~s{<p class="filmdown-dialogue">Hello, world.</p>}
    end

    test "parses a TRANSITION line" do
      html = Parser.parse("TRANSITION:: FADE OUT.")
      assert html =~ ~s{<p class="filmdown-transition">FADE OUT.</p>}
    end

    test "parses a SHOT line" do
      html = Parser.parse("SHOT:: CLOSE ON: a ticking clock")
      assert html =~ ~s{<p class="filmdown-shot">CLOSE ON: a ticking clock</p>}
    end

    test "parses a GENERALTEXT line" do
      html = Parser.parse("GENERALTEXT:: Some general text.")
      assert html =~ ~s{<p class="filmdown-general-text">Some general text.</p>}
    end

    test "parses a CENTREDGENERALTEXT line" do
      html = Parser.parse("CENTREDGENERALTEXT:: Centred text.")
      assert html =~ ~s{<p class="filmdown-centred-general-text">Centred text.</p>}
    end

    test "ignores blank lines" do
      filmdown = """
      ACTION:: First line.

      ACTION:: Second line.
      """

      html = Parser.parse(filmdown)
      assert html =~ ~s{<p class="filmdown-action">First line.</p>}
      assert html =~ ~s{<p class="filmdown-action">Second line.</p>}
    end

    test "ignores whitespace-only lines" do
      filmdown = "ACTION:: First.\n   \nACTION:: Second."
      html = Parser.parse(filmdown)
      assert html =~ ~s{<p class="filmdown-action">First.</p>}
      assert html =~ ~s{<p class="filmdown-action">Second.</p>}
    end

    test "ignores lines with an unrecognised identifier" do
      html = Parser.parse("UNKNOWN:: Something.")
      refute html =~ "Something."
    end

    test "escapes HTML special characters in content" do
      html = Parser.parse("ACTION:: A & B < C > D")
      assert html =~ "A &amp; B &lt; C &gt; D"
    end

    test "content may itself contain :: without confusion" do
      html = Parser.parse("DIALOGUE:: Wait:: what?")
      assert html =~ ~s{<p class="filmdown-dialogue">Wait:: what?</p>}
    end

    test "trims leading and trailing whitespace from content" do
      html = Parser.parse("ACTION::   padded content   ")
      assert html =~ ~s{<p class="filmdown-action">padded content</p>}
    end

    test "parses a multi-line filmdown document" do
      filmdown = """
      SCENEHEADING:: INT. HOUSE - NIGHT
      ACTION:: The door creaks open.
      CHARACTER:: ALICE
      DIALOGUE:: Is anyone there?
      """

      html = Parser.parse(filmdown)
      assert html =~ ~s{<h1 class="filmdown-scene-heading">INT. HOUSE - NIGHT</h1>}
      assert html =~ ~s{<p class="filmdown-action">The door creaks open.</p>}
      assert html =~ ~s{<p class="filmdown-character">ALICE</p>}
      assert html =~ ~s{<p class="filmdown-dialogue">Is anyone there?</p>}
    end
  end

  # ---------------------------------------------------------------------------
  # Walker tests
  # ---------------------------------------------------------------------------

  describe "Filmdown.Walker.walk/1" do
    test "converts a scene-heading h1 back to filmdown" do
      html = ~s(<h1 class="filmdown-scene-heading">INT. OFFICE - DAY</h1>)
      assert Walker.walk(html) == "SCENEHEADING:: INT. OFFICE - DAY"
    end

    test "converts an action paragraph back to filmdown" do
      html = ~s(<p class="filmdown-action">A quiet room.</p>)
      assert Walker.walk(html) == "ACTION:: A quiet room."
    end

    test "unescapes HTML entities in content" do
      html = ~s(<p class="filmdown-action">A &amp; B &lt; C &gt; D</p>)
      assert Walker.walk(html) == "ACTION:: A & B < C > D"
    end

    test "does not double-unescape compound HTML entities" do
      # &amp;lt; in HTML should unescape to &lt; (not <)
      html = ~s(<p class="filmdown-action">&amp;lt;</p>)
      assert Walker.walk(html) == "ACTION:: &lt;"
    end

    test "walks multiple elements in order" do
      html = """
      <h1 class="filmdown-scene-heading">INT. HOUSE - NIGHT</h1>
      <p class="filmdown-action">The door creaks open.</p>
      <p class="filmdown-character">ALICE</p>
      <p class="filmdown-dialogue">Is anyone there?</p>
      """

      result = Walker.walk(html)
      lines = String.split(result, "\n")
      assert lines == [
        "SCENEHEADING:: INT. HOUSE - NIGHT",
        "ACTION:: The door creaks open.",
        "CHARACTER:: ALICE",
        "DIALOGUE:: Is anyone there?"
      ]
    end

    test "ignores unrecognised HTML elements" do
      html = ~s(<html><body>\n<p class="unknown">ignored</p>\n</body></html>)
      assert Walker.walk(html) == ""
    end
  end

  # ---------------------------------------------------------------------------
  # Convenience-function tests (Filmdown.to_html / Filmdown.to_filmdown)
  # ---------------------------------------------------------------------------

  describe "Filmdown top-level API" do
    test "to_html/1 delegates to Parser" do
      assert Filmdown.to_html("ACTION:: test") == Parser.parse("ACTION:: test")
    end

    test "to_filmdown/1 delegates to Walker" do
      html = Parser.parse("ACTION:: test")
      assert Filmdown.to_filmdown(html) == Walker.walk(html)
    end
  end
end
