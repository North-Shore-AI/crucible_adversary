#!/usr/bin/env elixir

# Model Evaluation Example
# Demonstrates comprehensive robustness evaluation of AI models

IO.puts("\n=== CrucibleAdversary: Model Evaluation Example ===\n")

# ========================================
# 1. Define Sample Models
# ========================================

defmodule SentimentClassifier do
  @moduledoc """
  Simple sentiment classifier that looks for positive/negative keywords
  """

  def predict(input) do
    input_lower = String.downcase(input)

    positive_words = ["good", "great", "excellent", "positive", "happy", "love"]
    negative_words = ["bad", "terrible", "negative", "sad", "hate", "awful"]

    positive_count = Enum.count(positive_words, &String.contains?(input_lower, &1))
    negative_count = Enum.count(negative_words, &String.contains?(input_lower, &1))

    cond do
      positive_count > negative_count -> :positive
      negative_count > positive_count -> :negative
      true -> :neutral
    end
  end
end

defmodule TextClassifier do
  @moduledoc """
  Simple text classifier that categorizes by topic
  """

  def predict(input) do
    input_lower = String.downcase(input)

    cond do
      String.contains?(input_lower, ["tech", "computer", "software", "code"]) -> :technology
      String.contains?(input_lower, ["sport", "game", "player", "team"]) -> :sports
      String.contains?(input_lower, ["science", "research", "study", "experiment"]) -> :science
      true -> :general
    end
  end
end

# ========================================
# 2. Prepare Test Sets
# ========================================
IO.puts("--- Preparing Test Data ---\n")

sentiment_test_set = [
  {"This is a great product", :positive},
  {"I love this so much", :positive},
  {"The service was excellent", :positive},
  {"This is terrible", :negative},
  {"I hate this product", :negative},
  {"Very bad experience", :negative},
  {"It's okay", :neutral},
  {"Nothing special", :neutral}
]

text_test_set = [
  {"Software development with Python", :technology},
  {"Machine learning and AI research", :technology},
  {"Basketball championship game", :sports},
  {"Scientific study on climate", :science},
  {"Research paper on physics", :science}
]

IO.puts("Sentiment test set: #{length(sentiment_test_set)} samples")
IO.puts("Text classification test set: #{length(text_test_set)} samples\n")

# ========================================
# 3. Basic Model Evaluation
# ========================================
IO.puts("--- Basic Model Evaluation ---\n")

IO.puts("Evaluating SentimentClassifier...")

{:ok, sentiment_eval} =
  CrucibleAdversary.evaluate(
    SentimentClassifier,
    sentiment_test_set,
    attacks: [:character_swap, :word_deletion],
    metrics: [:accuracy_drop, :asr],
    seed: 42
  )

IO.puts("  Test Set Size: #{sentiment_eval.test_set_size}")
IO.puts("  Attack Types: #{inspect(sentiment_eval.attack_types)}")
IO.puts("  Metrics Computed: #{inspect(Map.keys(sentiment_eval.metrics))}\n")

# ========================================
# 4. Accuracy Drop Analysis
# ========================================
IO.puts("--- Accuracy Drop Analysis ---\n")

accuracy = sentiment_eval.metrics.accuracy_drop

IO.puts("Original Accuracy: #{Float.round(accuracy.original_accuracy * 100, 1)}%")
IO.puts("Attacked Accuracy: #{Float.round(accuracy.attacked_accuracy * 100, 1)}%")
IO.puts("Absolute Drop: #{Float.round(accuracy.absolute_drop * 100, 1)} percentage points")
IO.puts("Relative Drop: #{Float.round(accuracy.relative_drop * 100, 1)}%")
IO.puts("Severity: #{accuracy.severity}\n")

# Interpret severity
severity_msg =
  case accuracy.severity do
    :low -> "Model is highly robust to these attacks"
    :moderate -> "Model shows moderate vulnerability"
    :high -> "Model has significant robustness issues"
    :critical -> "Model is critically vulnerable"
  end

IO.puts("Assessment: #{severity_msg}\n")

# ========================================
# 5. Attack Success Rate Analysis
# ========================================
IO.puts("--- Attack Success Rate (ASR) Analysis ---\n")

asr = sentiment_eval.metrics.asr

IO.puts("Overall ASR: #{Float.round(asr.overall_asr * 100, 1)}%")
IO.puts("Total Attacks: #{asr.total_attacks}")
IO.puts("Successful Attacks: #{asr.successful_attacks}\n")

IO.puts("ASR by Attack Type:")

for {attack_type, rate} <- asr.by_attack_type do
  IO.puts("  #{attack_type}: #{Float.round(rate * 100, 1)}%")
end

IO.puts("")

# ========================================
# 6. Vulnerability Identification
# ========================================
IO.puts("--- Identified Vulnerabilities ---\n")

if length(sentiment_eval.vulnerabilities) > 0 do
  for vuln <- sentiment_eval.vulnerabilities do
    IO.puts("Type: #{vuln.type}")
    IO.puts("  Severity: #{vuln.severity}")
    IO.puts("  Details: #{vuln.details}")
    IO.puts("")
  end
else
  IO.puts("No significant vulnerabilities detected.\n")
end

# ========================================
# 7. Comprehensive Evaluation with All Attack Types
# ========================================
IO.puts("--- Comprehensive Robustness Evaluation ---\n")

IO.puts("Testing with multiple attack categories...")

{:ok, comprehensive_eval} =
  CrucibleAdversary.evaluate(
    SentimentClassifier,
    sentiment_test_set,
    attacks: [
      :character_swap,
      :character_delete,
      :word_deletion,
      :synonym_replacement,
      :semantic_paraphrase,
      :prompt_injection_basic
    ],
    metrics: [:accuracy_drop, :asr],
    seed: 42
  )

IO.puts("\nComprehensive Evaluation Results:")
IO.puts("  Attack Types Tested: #{length(comprehensive_eval.attack_types)}")

comp_accuracy = comprehensive_eval.metrics.accuracy_drop
IO.puts("\nAccuracy Performance:")
IO.puts("  Original: #{Float.round(comp_accuracy.original_accuracy * 100, 1)}%")
IO.puts("  Under Attack: #{Float.round(comp_accuracy.attacked_accuracy * 100, 1)}%")
IO.puts("  Drop: #{Float.round(comp_accuracy.absolute_drop * 100, 1)}pp")
IO.puts("  Severity: #{comp_accuracy.severity}")

comp_asr = comprehensive_eval.metrics.asr
IO.puts("\nAttack Success Rates:")

for {attack_type, rate} <- comp_asr.by_attack_type |> Enum.sort_by(fn {_, r} -> -r end) do
  bar = String.duplicate("=", round(rate * 50))

  IO.puts(
    "  #{String.pad_trailing(to_string(attack_type), 25)}: #{String.pad_leading("#{Float.round(rate * 100, 1)}%", 6)} #{bar}"
  )
end

IO.puts("")

# ========================================
# 8. Batch Attack Demonstration
# ========================================
IO.puts("--- Batch Attack Processing ---\n")

sample_inputs = [
  "This product is excellent and I love it",
  "Terrible experience, very disappointing",
  "Average quality, nothing special"
]

IO.puts("Attacking #{length(sample_inputs)} inputs with multiple attack types...")

{:ok, batch_results} =
  CrucibleAdversary.attack_batch(
    sample_inputs,
    types: [:character_swap, :word_deletion, :synonym_replacement],
    seed: 42
  )

IO.puts("Generated #{length(batch_results)} adversarial examples\n")

IO.puts("Sample Results:")

for {input, idx} <- Enum.with_index(sample_inputs, 1) do
  IO.puts("\nOriginal #{idx}: \"#{input}\"")
  original_pred = SentimentClassifier.predict(input)
  IO.puts("  Prediction: #{original_pred}")

  input_results = Enum.filter(batch_results, &(&1.original == input))

  for result <- Enum.take(input_results, 2) do
    attacked_pred = SentimentClassifier.predict(result.attacked)
    flip = if attacked_pred != original_pred, do: " [FLIPPED!]", else: ""
    IO.puts("  #{result.attack_type}: \"#{result.attacked}\"")
    IO.puts("    New Prediction: #{attacked_pred}#{flip}")
  end
end

IO.puts("")

# ========================================
# 9. Model Comparison
# ========================================
IO.puts("--- Model Comparison ---\n")

IO.puts("Comparing robustness of different models...\n")

# Evaluate both models with same attacks
{:ok, sentiment_result} =
  CrucibleAdversary.evaluate(
    SentimentClassifier,
    sentiment_test_set,
    attacks: [:character_swap, :word_deletion],
    metrics: [:accuracy_drop],
    seed: 42
  )

{:ok, text_result} =
  CrucibleAdversary.evaluate(
    TextClassifier,
    text_test_set,
    attacks: [:character_swap, :word_deletion],
    metrics: [:accuracy_drop],
    seed: 42
  )

IO.puts("Model Robustness Comparison:")
IO.puts("\nSentimentClassifier:")

IO.puts(
  "  Original Accuracy: #{Float.round(sentiment_result.metrics.accuracy_drop.original_accuracy * 100, 1)}%"
)

IO.puts(
  "  Robust Accuracy: #{Float.round(sentiment_result.metrics.accuracy_drop.attacked_accuracy * 100, 1)}%"
)

IO.puts(
  "  Robustness Score: #{Float.round((1 - sentiment_result.metrics.accuracy_drop.absolute_drop) * 100, 1)}%"
)

IO.puts("\nTextClassifier:")

IO.puts(
  "  Original Accuracy: #{Float.round(text_result.metrics.accuracy_drop.original_accuracy * 100, 1)}%"
)

IO.puts(
  "  Robust Accuracy: #{Float.round(text_result.metrics.accuracy_drop.attacked_accuracy * 100, 1)}%"
)

IO.puts(
  "  Robustness Score: #{Float.round((1 - text_result.metrics.accuracy_drop.absolute_drop) * 100, 1)}%"
)

# Determine winner
sentiment_robustness = 1 - sentiment_result.metrics.accuracy_drop.absolute_drop
text_robustness = 1 - text_result.metrics.accuracy_drop.absolute_drop

winner =
  if sentiment_robustness > text_robustness do
    "SentimentClassifier"
  else
    "TextClassifier"
  end

IO.puts("\nMost Robust Model: #{winner}\n")

# ========================================
# 10. Evaluation Summary and Recommendations
# ========================================
IO.puts("--- Evaluation Summary ---\n")

IO.puts("Key Findings:")
IO.puts("1. Models show varying vulnerability to different attack types")
IO.puts("2. Character-level attacks often have lower success rates")
IO.puts("3. Word-level and semantic attacks can be more effective")
IO.puts("4. Robustness varies significantly across model types\n")

IO.puts("Recommendations:")
IO.puts("1. Implement input validation and sanitization")
IO.puts("2. Add adversarial training with these attack types")
IO.puts("3. Monitor for unusual input patterns in production")
IO.puts("4. Regularly evaluate robustness with new attack techniques")
IO.puts("5. Focus defense on high-ASR attack types\n")

IO.puts("=== Model Evaluation Example Complete ===\n")
