defmodule Filmdown.RoundtripTest do
  @moduledoc """
  Round-trip identity tests for the filmdown parser and walker.

  Generates N valid filmdown documents, converts each to HTML via the parser,
  then walks the HTML back to filmdown, and asserts that the result matches the
  original (ignoring blank lines, since the parser drops them).

  The number of documents to generate is controlled by the module attribute
  `@num_documents` below.
  """

  use ExUnit.Case

  # Number of random filmdown documents to generate and test.  Increase to
  # exercise more cases; the default of 100 keeps the suite fast.
  @num_documents 100

  # Maximum number of lines per generated document.
  @max_lines 20

  # Maximum number of characters in a generated content fragment.
  @max_content_length 60

  @valid_identifiers ~w(
    SCENEHEADING
    ACTION
    CHARACTER
    PARENTHETICAL
    DIALOGUE
    TRANSITION
    SHOT
    GENERALTEXT
    CENTREDGENERALTEXT
  )

  # Printable ASCII characters that are safe to use in filmdown content.
  # We exclude &, <, > (HTML-unsafe), newlines, and the :: sequence so that
  # the content is self-consistent without requiring deeper escaping logic in
  # the generator itself.  The parser/walker still handle those characters
  # correctly (see the unit tests in filmdown_test.exs).
  @safe_chars (for c <- 32..126,
                   c not in [?&, ?<, ?>],
                   c != ?:,
                   do: <<c::utf8>>)

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "round-trip identity for #{@num_documents} generated filmdown documents" do
    for n <- 1..@num_documents do
      filmdown = generate_filmdown(n)

      html = Filmdown.to_html(filmdown)
      regenerated = Filmdown.to_filmdown(html)
      # Strip blank lines and trim content from each line, because the parser
      # trims content and drops blank lines (as per spec).
      canonical =
        filmdown
        |> String.split("\n")
        |> Enum.reject(&(String.trim(&1) == ""))
        |> Enum.map(fn line ->
          case String.split(line, "::", parts: 2) do
            [identifier, content] ->
              "#{String.trim(identifier)}:: #{String.trim(content)}"
            _ ->
              line
          end
        end)
        |> Enum.join("\n")

      assert regenerated == canonical,
             """
             Round-trip failure on document #{n}.

             Original (canonical):
             #{canonical}

             Regenerated:
             #{regenerated}
             """
    end
  end

  # ---------------------------------------------------------------------------
  # Generator helpers
  # ---------------------------------------------------------------------------

  # Generates a deterministic-but-varied filmdown document using `seed` to
  # drive all pseudo-random choices.  Using a seed means failures are
  # reproducible: re-run with the same @num_documents to get the same files.
  defp generate_filmdown(seed) do
    # Build a simple deterministic pseudo-random state from the seed.
    state = :rand.seed_s(:exsss, {seed, seed * 7, seed * 13})

    num_lines = max(1, rem(seed, @max_lines))

    {lines, _state} =
      Enum.reduce(1..num_lines, {[], state}, fn _, {acc, st} ->
        {identifier, st1} = random_identifier(st)
        {content, st2} = random_content(st1)
        {acc ++ ["#{identifier}:: #{content}"], st2}
      end)

    Enum.join(lines, "\n")
  end

  defp random_identifier(state) do
    {idx, new_state} = :rand.uniform_s(length(@valid_identifiers), state)
    {Enum.at(@valid_identifiers, idx - 1), new_state}
  end

  defp random_content(state) do
    {len, state1} = :rand.uniform_s(@max_content_length, state)
    len = max(1, len)

    {chars, final_state} =
      Enum.reduce(1..len, {[], state1}, fn _, {acc, st} ->
        {idx, st2} = :rand.uniform_s(length(@safe_chars), st)
        {acc ++ [Enum.at(@safe_chars, idx - 1)], st2}
      end)

    {Enum.join(chars), final_state}
  end
end
