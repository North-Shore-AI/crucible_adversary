defmodule CrucibleAdversary.Defenses.Sanitization do
  @moduledoc """
  Input sanitization mechanisms.

  Provides sanitization capabilities to clean potentially malicious inputs
  while preserving legitimate content.

  ## Strategies

  - `:remove_delimiters` - Remove common delimiter patterns
  - `:normalize_whitespace` - Normalize excessive whitespace
  - `:length_limit` - Truncate to maximum length
  - `:remove_special_chars` - Remove potentially dangerous characters
  - `:trim` - Trim leading/trailing whitespace

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Sanitization
      iex> result = Sanitization.sanitize("Text  with   spaces", strategies: [:normalize_whitespace])
      iex> result.sanitized
      "Text with spaces"
  """

  @default_strategies [:remove_delimiters, :normalize_whitespace, :trim]
  @default_max_length 10_000
  @delimiters ["###", "---", "```", "===", "***", "~~~"]

  @doc """
  Sanitizes input by applying specified strategies.

  ## Options
    * `:strategies` - List of sanitization strategies (default: [:remove_delimiters, :normalize_whitespace, :trim])
    * `:max_length` - Maximum length for truncation (default: 10000)

  ## Returns
    Map containing:
    * `:sanitized` - Sanitized text
    * `:changes_made` - Boolean indicating if changes were made
    * `:metadata` - Map of metadata about sanitization
    * `:original` - Original input text

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Sanitization
      iex> result = Sanitization.sanitize("Clean text")
      iex> result.sanitized
      "Clean text"
  """
  @spec sanitize(String.t(), keyword()) :: map()
  def sanitize(text, opts \\ []) do
    strategies = Keyword.get(opts, :strategies, @default_strategies)
    max_length = Keyword.get(opts, :max_length, @default_max_length)

    original = text

    sanitized =
      Enum.reduce(strategies, text, fn strategy, acc ->
        apply_strategy(acc, strategy, opts)
      end)
      |> maybe_limit_length(max_length, :length_limit in strategies)

    %{
      sanitized: sanitized,
      changes_made: sanitized != original,
      metadata: %{
        strategies_applied: strategies,
        original_length: String.length(original),
        sanitized_length: String.length(sanitized)
      },
      original: original
    }
  end

  @doc """
  Removes specified patterns from text.

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Sanitization
      iex> Sanitization.remove_patterns("Test ### here", ["###"])
      "Test  here"
  """
  @spec remove_patterns(String.t(), list(String.t())) :: String.t()
  def remove_patterns(text, patterns) do
    Enum.reduce(patterns, text, fn pattern, acc ->
      String.replace(acc, pattern, "")
    end)
  end

  # Private helpers

  defp apply_strategy(text, :remove_delimiters, _opts) do
    remove_patterns(text, @delimiters)
  end

  defp apply_strategy(text, :normalize_whitespace, _opts) do
    text
    |> String.replace(~r/\s+/, " ")
  end

  defp apply_strategy(text, :trim, _opts) do
    String.trim(text)
  end

  defp apply_strategy(text, :remove_special_chars, _opts) do
    text
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/[^\w\s.,!?-]/, "")
  end

  defp apply_strategy(text, _unknown, _opts) do
    text
  end

  defp maybe_limit_length(text, max_length, true) do
    String.slice(text, 0, max_length)
  end

  defp maybe_limit_length(text, _max_length, false) do
    text
  end
end
