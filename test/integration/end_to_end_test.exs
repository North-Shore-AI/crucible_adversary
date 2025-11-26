defmodule CrucibleAdversary.Integration.EndToEndTest do
  use ExUnit.Case

  @moduletag :integration

  describe "End-to-End Adversarial Testing Pipeline" do
    test "complete workflow: attacks, evaluation, and reporting" do
      # Step 1: Define a simple sentiment analysis model
      sentiment_model = fn input ->
        cond do
          String.contains?(String.downcase(input), "positive") -> :positive
          String.contains?(String.downcase(input), "negative") -> :negative
          true -> :neutral
        end
      end

      # Step 2: Create a test dataset
      test_set = [
        {"This is a positive example", :positive},
        {"This is a negative example", :negative},
        {"A positive sentiment", :positive},
        {"negative feedback here", :negative},
        {"very positive outcome", :positive}
      ]

      # Step 3: Perform individual attacks to understand attack behavior
      {:ok, char_attack} =
        CrucibleAdversary.attack(
          "This is a positive example",
          type: :character_swap,
          rate: 0.15,
          seed: 42
        )

      assert char_attack.attack_type == :character_swap
      assert char_attack.attacked != char_attack.original

      {:ok, word_attack} =
        CrucibleAdversary.attack(
          "This is a positive example",
          type: :word_deletion,
          rate: 0.3,
          seed: 42
        )

      assert word_attack.attack_type == :word_deletion

      # Step 4: Batch attack multiple inputs
      {:ok, batch_results} =
        CrucibleAdversary.attack_batch(
          ["positive test", "negative example"],
          types: [:character_swap, :synonym_replacement],
          seed: 42
        )

      # 2 inputs × 2 attack types
      assert length(batch_results) == 4

      # Step 5: Comprehensive robustness evaluation
      {:ok, eval_result} =
        CrucibleAdversary.evaluate(
          sentiment_model,
          test_set,
          attacks: [:character_swap, :word_deletion, :synonym_replacement],
          metrics: [:accuracy_drop, :asr],
          seed: 42
        )

      # Verify evaluation result structure
      assert eval_result.test_set_size == 5
      assert length(eval_result.attack_types) == 3
      assert Map.has_key?(eval_result.metrics, :accuracy_drop)
      assert Map.has_key?(eval_result.metrics, :asr)

      # Verify metrics are calculated
      accuracy_drop = eval_result.metrics.accuracy_drop
      assert is_float(accuracy_drop.original_accuracy)
      assert is_float(accuracy_drop.attacked_accuracy)
      assert is_float(accuracy_drop.absolute_drop)
      assert accuracy_drop.severity in [:low, :moderate, :high, :critical]

      asr = eval_result.metrics.asr
      assert is_float(asr.overall_asr)
      assert is_map(asr.by_attack_type)
      assert Map.has_key?(asr.by_attack_type, :character_swap)

      # Verify vulnerabilities are identified (if any)
      assert is_list(eval_result.vulnerabilities)

      # Step 6: Configuration management
      original_config = CrucibleAdversary.config()
      original_rate = original_config.default_attack_rate

      :ok = CrucibleAdversary.configure(default_attack_rate: 0.25)
      new_config = CrucibleAdversary.config()
      assert new_config.default_attack_rate == 0.25

      # Reset config
      :ok = CrucibleAdversary.configure(default_attack_rate: original_rate)

      # Step 7: Verify version
      version = CrucibleAdversary.version()
      assert version == "0.3.0"
    end

    test "robustness evaluation with different attack combinations" do
      # Model that's vulnerable to character-level attacks
      simple_model = fn input -> String.upcase(input) end

      test_set = [
        {"hello", "HELLO"},
        {"world", "WORLD"},
        {"test", "TEST"}
      ]

      # Test character-level attacks only
      {:ok, char_eval} =
        CrucibleAdversary.evaluate(
          simple_model,
          test_set,
          attacks: [:character_swap, :character_delete],
          metrics: [:accuracy_drop],
          seed: 42
        )

      assert char_eval.test_set_size == 3
      assert :character_swap in char_eval.attack_types
      assert :character_delete in char_eval.attack_types

      # Test word-level attacks only
      {:ok, word_eval} =
        CrucibleAdversary.evaluate(
          simple_model,
          test_set,
          attacks: [:word_deletion, :word_shuffle],
          metrics: [:asr],
          seed: 42
        )

      assert :word_deletion in word_eval.attack_types
      assert :word_shuffle in word_eval.attack_types
      assert Map.has_key?(word_eval.metrics, :asr)
    end

    test "attack pipeline with all available attack types" do
      input = "The quick brown fox jumps over the lazy dog"

      attack_types = [
        :character_swap,
        :character_delete,
        :character_insert,
        :homoglyph,
        :keyboard_typo,
        :word_deletion,
        :word_insertion,
        :synonym_replacement,
        :word_shuffle
      ]

      # Perform all attack types
      results =
        for attack_type <- attack_types do
          {:ok, result} =
            CrucibleAdversary.attack(
              input,
              type: attack_type,
              rate: 0.15,
              seed: 42
            )

          result
        end

      # Verify all attacks executed
      assert length(results) == 9
      assert Enum.all?(results, fn r -> r.original == input end)
      assert Enum.all?(results, fn r -> r.attack_type in attack_types end)

      # Verify each attack type is unique
      attack_types_executed = Enum.map(results, & &1.attack_type)
      assert Enum.uniq(attack_types_executed) == attack_types_executed
    end
  end
end
