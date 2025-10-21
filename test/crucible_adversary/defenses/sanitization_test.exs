defmodule CrucibleAdversary.Defenses.SanitizationTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Defenses.Sanitization

  describe "sanitize/2" do
    test "removes delimiters from input" do
      input = "Text ### with ### delimiters"

      result = Sanitization.sanitize(input, strategies: [:remove_delimiters])

      assert result.sanitized != input
      refute String.contains?(result.sanitized, "###")
      assert result.changes_made == true
    end

    test "normalizes whitespace" do
      input = "Too    many     spaces"

      result = Sanitization.sanitize(input, strategies: [:normalize_whitespace])

      assert result.sanitized == "Too many spaces"
      assert result.changes_made == true
    end

    test "truncates to maximum length" do
      input = String.duplicate("a", 1000)

      result = Sanitization.sanitize(input, strategies: [:length_limit], max_length: 100)

      assert String.length(result.sanitized) == 100
      assert result.changes_made == true
    end

    test "removes special characters" do
      input = "Test <script> alert() </script>"

      result = Sanitization.sanitize(input, strategies: [:remove_special_chars])

      refute String.contains?(result.sanitized, "<script>")
      assert result.changes_made == true
    end

    test "applies multiple strategies" do
      input = "Text  ###  with   issues   "

      result =
        Sanitization.sanitize(input,
          strategies: [:remove_delimiters, :normalize_whitespace, :trim]
        )

      refute String.contains?(result.sanitized, "###")
      refute String.contains?(result.sanitized, "  ")
      assert result.sanitized == String.trim(result.sanitized)
      assert result.changes_made == true
    end

    test "handles empty string" do
      result = Sanitization.sanitize("")

      assert result.sanitized == ""
      assert result.changes_made == false
    end

    test "tracks metadata" do
      result = Sanitization.sanitize("test ###", strategies: [:remove_delimiters])

      assert Map.has_key?(result.metadata, :strategies_applied)
    end

    test "returns no changes for clean input" do
      input = "Clean normal text"

      result = Sanitization.sanitize(input, strategies: [:remove_delimiters])

      assert result.sanitized == input
      assert result.changes_made == false
    end
  end

  describe "remove_patterns/2" do
    test "removes specified patterns" do
      input = "Text with ### delimiters"

      result = Sanitization.remove_patterns(input, ["###"])

      refute String.contains?(result, "###")
    end

    test "handles multiple patterns" do
      input = "Text ### with --- multiple"

      result = Sanitization.remove_patterns(input, ["###", "---"])

      refute String.contains?(result, "###")
      refute String.contains?(result, "---")
    end

    test "preserves other content" do
      input = "Keep this ### remove that"

      result = Sanitization.remove_patterns(input, ["###"])

      assert String.contains?(result, "Keep this")
      assert String.contains?(result, "remove that")
    end
  end
end
