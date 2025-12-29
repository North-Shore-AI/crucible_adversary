defmodule CrucibleAdversary.Defenses.Filtering do
  @moduledoc """
  Input filtering mechanisms to block adversarial inputs.

  Provides filtering capabilities to reject potentially malicious inputs
  before they reach the model.

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Filtering
      iex> result = Filtering.filter_input("Normal text")
      iex> result.filtered
      false
  """

  alias CrucibleAdversary.Defenses.Detection

  @default_patterns [:prompt_injection, :delimiter, :roleplay]

  @doc """
  Filters input based on detected adversarial patterns.

  ## Options
    * `:patterns` - List of patterns to filter (default: [:prompt_injection, :delimiter, :roleplay])
    * `:mode` - Filtering mode (:strict, :permissive) (default: :strict)

  ## Returns
    Map containing:
    * `:filtered` - Boolean indicating if input was filtered
    * `:reason` - Atom indicating why input was filtered (if filtered)
    * `:original` - Original input text
    * `:safe_input` - Safe input if not filtered, nil if filtered

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Filtering
      iex> result = Filtering.filter_input("Clean text")
      iex> result.filtered
      false
  """
  @spec filter_input(String.t(), keyword()) :: map()
  def filter_input(text, opts \\ []) do
    patterns = Keyword.get(opts, :patterns, @default_patterns)
    mode = Keyword.get(opts, :mode, :strict)

    # Detect patterns
    detected =
      patterns
      |> Enum.find(fn pattern ->
        Detection.detect_pattern(text, pattern)
      end)

    filtered =
      case {detected, mode} do
        {nil, _} -> false
        {_pattern, :strict} -> true
        {_pattern, :permissive} -> should_filter_permissive?(text)
      end

    if filtered do
      %{
        filtered: true,
        reason: pattern_to_reason(detected),
        original: text,
        safe_input: nil
      }
    else
      %{
        filtered: false,
        reason: nil,
        original: text,
        safe_input: text
      }
    end
  end

  @doc """
  Checks if input is safe.

  ## Options
    * `:patterns` - List of patterns to check (default: [:prompt_injection, :delimiter, :roleplay])

  ## Returns
    Boolean indicating if input is safe

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Filtering
      iex> Filtering.safe?("Hello")
      true
  """
  @spec safe?(String.t(), keyword()) :: boolean()
  def safe?(text, opts \\ []) do
    patterns = Keyword.get(opts, :patterns, @default_patterns)

    not Enum.any?(patterns, fn pattern ->
      Detection.detect_pattern(text, pattern)
    end)
  end

  # Private helpers

  defp pattern_to_reason(:prompt_injection), do: :prompt_injection_detected
  defp pattern_to_reason(:delimiter), do: :delimiter_detected
  defp pattern_to_reason(:roleplay), do: :roleplay_detected
  defp pattern_to_reason(:encoding), do: :encoding_detected
  defp pattern_to_reason(_), do: :unknown_pattern_detected

  defp should_filter_permissive?(text) do
    # In permissive mode, only filter if confidence is very high
    detection = Detection.detect_attack(text)
    detection.confidence > 0.8
  end
end
