defmodule CrucibleAdversary.Metrics.AccuracyTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Metrics.Accuracy

  describe "drop/2" do
    test "calculates accuracy drop between clean and adversarial results" do
      original = [
        {:pred1, :label1, true},
        {:pred2, :label2, true},
        {:pred3, :label3, true},
        {:pred4, :label4, true},
        {:pred5, :label5, false}
      ]

      attacked = [
        {:pred1, :label1, true},
        {:pred2, :label2, false},
        {:pred3, :label3, false},
        {:pred4, :label4, true},
        {:pred5, :label5, false}
      ]

      result = Accuracy.drop(original, attacked)

      assert result.original_accuracy == 0.8
      assert result.attacked_accuracy == 0.4
      assert result.absolute_drop == 0.4
      assert_in_delta result.relative_drop, 0.5, 0.01
      assert result.severity == :critical
    end

    test "handles perfect accuracy" do
      results = [
        {:pred1, :label1, true},
        {:pred2, :label2, true}
      ]

      result = Accuracy.drop(results, results)

      assert result.original_accuracy == 1.0
      assert result.attacked_accuracy == 1.0
      assert result.absolute_drop == 0.0
      assert result.relative_drop == 0.0
      assert result.severity == :low
    end

    test "handles zero accuracy" do
      original = [{:pred1, :label1, true}]
      attacked = [{:pred1, :label1, false}]

      result = Accuracy.drop(original, attacked)

      assert result.original_accuracy == 1.0
      assert result.attacked_accuracy == 0.0
      assert result.absolute_drop == 1.0
      assert result.relative_drop == 1.0
      assert result.severity == :critical
    end

    test "classifies severity levels correctly" do
      # Low severity (< 5% relative drop)
      original = List.duplicate({:p, :l, true}, 100)
      attacked = List.duplicate({:p, :l, true}, 98) ++ List.duplicate({:p, :l, false}, 2)
      result = Accuracy.drop(original, attacked)
      assert result.severity == :low

      # Moderate severity (5-15%)
      attacked = List.duplicate({:p, :l, true}, 90) ++ List.duplicate({:p, :l, false}, 10)
      result = Accuracy.drop(original, attacked)
      assert result.severity == :moderate

      # High severity (15-30%)
      attacked = List.duplicate({:p, :l, true}, 80) ++ List.duplicate({:p, :l, false}, 20)
      result = Accuracy.drop(original, attacked)
      assert result.severity == :high

      # Critical severity (>= 30%)
      attacked = List.duplicate({:p, :l, true}, 65) ++ List.duplicate({:p, :l, false}, 35)
      result = Accuracy.drop(original, attacked)
      assert result.severity == :critical
    end
  end

  describe "robust_accuracy/2" do
    test "calculates accuracy on predictions and labels" do
      predictions = [:cat, :dog, :cat, :bird, :dog]
      ground_truth = [:cat, :dog, :bird, :bird, :dog]

      accuracy = Accuracy.robust_accuracy(predictions, ground_truth)

      assert accuracy == 0.8
    end

    test "handles all correct" do
      predictions = [:a, :b, :c]
      ground_truth = [:a, :b, :c]

      accuracy = Accuracy.robust_accuracy(predictions, ground_truth)

      assert accuracy == 1.0
    end

    test "handles all incorrect" do
      predictions = [:a, :b, :c]
      ground_truth = [:x, :y, :z]

      accuracy = Accuracy.robust_accuracy(predictions, ground_truth)

      assert accuracy == 0.0
    end

    test "handles empty lists" do
      accuracy = Accuracy.robust_accuracy([], [])

      assert accuracy == 0.0
    end
  end
end
