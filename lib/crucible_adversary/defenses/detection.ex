defmodule CrucibleAdversary.Defenses.Detection do
  @moduledoc """
  Attack detection mechanisms.

  Provides various detectors to identify potentially adversarial inputs
  before they reach the model.

  ## Detectors

  - `:prompt_injection` - Detects prompt injection keywords
  - `:delimiter` - Detects delimiter confusion patterns
  - `:roleplay` - Detects roleplay/jailbreak attempts
  - `:encoding` - Detects encoded payloads
  - `:anomaly` - Detects statistical anomalies

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Detection
      iex> result = Detection.detect_attack("Ignore previous instructions")
      iex> result.is_adversarial
      true
  """

  @default_detectors [:prompt_injection, :delimiter, :roleplay]

  @doc """
  Detects adversarial patterns in input text.

  ## Options
    * `:detectors` - List of detectors to use (default: [:prompt_injection, :delimiter, :roleplay])

  ## Returns
    Map containing:
    * `:is_adversarial` - Boolean indicating if input is adversarial
    * `:confidence` - Confidence score (0.0-1.0)
    * `:detected_patterns` - List of detected attack patterns
    * `:risk_level` - Risk level (:low, :medium, :high, :critical)

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Detection
      iex> result = Detection.detect_attack("Normal text")
      iex> result.is_adversarial
      false
  """
  @spec detect_attack(String.t(), keyword()) :: map()
  def detect_attack(text, opts \\ []) do
    detectors = Keyword.get(opts, :detectors, @default_detectors)

    detected_patterns =
      detectors
      |> Enum.filter(fn detector ->
        detect_pattern(text, detector)
      end)

    confidence = calculate_confidence(detected_patterns, text)
    is_adversarial = confidence > 0.5
    risk_level = calculate_risk_level(confidence)

    %{
      is_adversarial: is_adversarial,
      confidence: confidence,
      detected_patterns: detected_patterns,
      risk_level: risk_level
    }
  end

  @doc """
  Calculates risk level from confidence score.

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Detection
      iex> Detection.calculate_risk_level(0.9)
      :critical
  """
  @spec calculate_risk_level(float()) :: atom()
  def calculate_risk_level(confidence) when confidence >= 0.8, do: :critical
  def calculate_risk_level(confidence) when confidence >= 0.6, do: :high
  def calculate_risk_level(confidence) when confidence >= 0.4, do: :medium
  def calculate_risk_level(_confidence), do: :low

  @doc """
  Detects specific pattern in text.

  ## Examples

      iex> alias CrucibleAdversary.Defenses.Detection
      iex> Detection.detect_pattern("ignore previous", :prompt_injection)
      true
  """
  @spec detect_pattern(String.t(), atom()) :: boolean()
  def detect_pattern(text, pattern_type) do
    lower_text = String.downcase(text)

    case pattern_type do
      :prompt_injection ->
        detect_prompt_injection(lower_text)

      :delimiter ->
        detect_delimiter(text)

      :roleplay ->
        detect_roleplay(lower_text)

      :encoding ->
        detect_encoding(text)

      :anomaly ->
        detect_anomaly(text)

      _ ->
        false
    end
  end

  # Private pattern detection functions

  @prompt_injection_keywords [
    "ignore previous",
    "ignore all previous",
    "disregard",
    "forget everything",
    "new instructions",
    "instead do",
    "system:",
    "override",
    "bypass"
  ]

  defp detect_prompt_injection(lower_text) do
    Enum.any?(@prompt_injection_keywords, fn keyword ->
      String.contains?(lower_text, keyword)
    end)
  end

  @delimiters ["###", "---", "```", "===", "***", "~~~"]

  defp detect_delimiter(text) do
    Enum.any?(@delimiters, fn delimiter ->
      String.contains?(text, delimiter)
    end)
  end

  @roleplay_keywords [
    "you are now",
    "pretend you are",
    "act as",
    "roleplay",
    "you are dan",
    "do anything now",
    "as a",
    "in character"
  ]

  defp detect_roleplay(lower_text) do
    Enum.any?(@roleplay_keywords, fn keyword ->
      String.contains?(lower_text, keyword)
    end)
  end

  defp detect_encoding(text) do
    # Simple heuristic: detect potential base64
    # Base64 has high ratio of alphanumeric to special chars
    alphanumeric_ratio = calculate_alphanumeric_ratio(text)

    alphanumeric_ratio > 0.95 and String.length(text) > 20 and
      String.contains?(text, ["=", "+", "/"])
  end

  defp detect_anomaly(text) do
    # Simple anomaly detection based on unusual patterns
    # Check for very long sequences without spaces
    words = String.split(text)
    max_word_length = words |> Enum.map(&String.length/1) |> Enum.max(fn -> 0 end)

    max_word_length > 50
  end

  defp calculate_alphanumeric_ratio(text) do
    if String.length(text) == 0 do
      0.0
    else
      alphanumeric_count =
        text
        |> String.graphemes()
        |> Enum.count(fn char -> char =~ ~r/[a-zA-Z0-9]/ end)

      alphanumeric_count / String.length(text)
    end
  end

  defp calculate_confidence(detected_patterns, text) do
    base_confidence =
      case length(detected_patterns) do
        0 -> 0.0
        1 -> 0.6
        2 -> 0.8
        _ -> 0.95
      end

    # Adjust based on text characteristics
    adjustment =
      cond do
        String.length(text) < 10 -> -0.1
        has_multiple_delimiters?(text) -> 0.1
        true -> 0.0
      end

    min(1.0, max(0.0, base_confidence + adjustment))
  end

  defp has_multiple_delimiters?(text) do
    delimiter_count =
      @delimiters
      |> Enum.count(fn delimiter -> String.contains?(text, delimiter) end)

    delimiter_count >= 2
  end
end
