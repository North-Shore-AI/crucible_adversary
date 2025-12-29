defmodule CrucibleAdversary.Evaluation.RobustnessTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Evaluation.Robustness
  alias CrucibleAdversary.EvaluationResult

  # Simple mock model that returns uppercase
  defp simple_model(input), do: String.upcase(input)

  # Mock model that checks for "positive" keyword
  defp sentiment_model(input) do
    if String.contains?(String.downcase(input), "positive") do
      :positive
    else
      :negative
    end
  end

  describe "evaluate/3" do
    test "evaluates model robustness with multiple attack types" do
      test_set = [
        {"hello world", "HELLO WORLD"},
        {"test input", "TEST INPUT"}
      ]

      {:ok, result} =
        Robustness.evaluate(
          &simple_model/1,
          test_set,
          attacks: [:character_swap, :word_deletion],
          metrics: [:accuracy_drop, :asr],
          seed: 42
        )

      assert %EvaluationResult{} = result
      assert result.test_set_size == 2
      assert :character_swap in result.attack_types
      assert :word_deletion in result.attack_types
      assert Map.has_key?(result.metrics, :accuracy_drop)
      assert Map.has_key?(result.metrics, :asr)
      assert %DateTime{} = result.timestamp
    end

    test "uses default attacks and metrics when not specified" do
      test_set = [{"test", "TEST"}]

      {:ok, result} = Robustness.evaluate(&simple_model/1, test_set)

      assert %EvaluationResult{} = result
      # Default attacks: [:character_swap, :word_deletion]
      assert result.attack_types != []
      # Default metrics: [:accuracy_drop, :asr]
      assert map_size(result.metrics) > 0
    end

    test "handles empty test set" do
      {:ok, result} = Robustness.evaluate(&simple_model/1, [])

      assert result.test_set_size == 0
      assert result.metrics == %{}
    end

    test "works with module-based model" do
      defmodule TestModel do
        def predict(input), do: String.upcase(input)
      end

      test_set = [{"hello", "HELLO"}]

      {:ok, result} =
        Robustness.evaluate(
          TestModel,
          test_set,
          attacks: [:character_swap],
          seed: 42
        )

      assert %EvaluationResult{} = result
      assert result.model == TestModel
    end

    test "calculates accuracy drop metric" do
      test_set = [
        {"positive example", :positive},
        {"negative example", :negative},
        {"positive test", :positive}
      ]

      {:ok, result} =
        Robustness.evaluate(
          &sentiment_model/1,
          test_set,
          attacks: [:word_deletion],
          metrics: [:accuracy_drop],
          seed: 42
        )

      assert Map.has_key?(result.metrics, :accuracy_drop)
      drop = result.metrics.accuracy_drop
      assert Map.has_key?(drop, :original_accuracy)
      assert Map.has_key?(drop, :attacked_accuracy)
    end

    test "calculates ASR metric" do
      test_set = [{"test", "TEST"}]

      {:ok, result} =
        Robustness.evaluate(
          &simple_model/1,
          test_set,
          attacks: [:character_swap],
          metrics: [:asr],
          seed: 42
        )

      assert Map.has_key?(result.metrics, :asr)
      asr = result.metrics.asr
      assert Map.has_key?(asr, :overall_asr)
      assert Map.has_key?(asr, :by_attack_type)
    end

    test "identifies vulnerabilities" do
      # Model that fails on perturbed input
      vulnerable_model = fn input ->
        if String.contains?(input, "test") do
          :pass
        else
          :fail
        end
      end

      test_set = [{"test input", :pass}]

      {:ok, result} =
        Robustness.evaluate(
          vulnerable_model,
          test_set,
          attacks: [:character_swap, :word_deletion],
          seed: 42
        )

      # Should identify vulnerabilities when attacks succeed
      assert is_list(result.vulnerabilities)
    end

    test "passes attack options to attack functions" do
      test_set = [{"test", "TEST"}]

      {:ok, result} =
        Robustness.evaluate(
          &simple_model/1,
          test_set,
          attacks: [:character_swap],
          attack_opts: [rate: 0.5],
          seed: 42
        )

      assert %EvaluationResult{} = result
    end
  end

  describe "evaluate_single/3" do
    test "evaluates a single input with multiple attacks" do
      input_pair = {"hello world", "HELLO WORLD"}

      results =
        Robustness.evaluate_single(
          &simple_model/1,
          input_pair,
          attacks: [:character_swap, :word_deletion],
          seed: 42
        )

      assert is_list(results)
      assert length(results) == 2
      assert Enum.all?(results, fn r -> Map.has_key?(r, :attack_type) end)
    end

    test "returns empty list when no attacks specified" do
      results =
        Robustness.evaluate_single(
          &simple_model/1,
          {"test", "TEST"},
          attacks: []
        )

      assert results == []
    end

    test "evaluates with function model" do
      results =
        Robustness.evaluate_single(
          &simple_model/1,
          {"test", "TEST"},
          attacks: [:character_swap],
          seed: 42
        )

      assert is_list(results)
      assert results != []
    end
  end
end
