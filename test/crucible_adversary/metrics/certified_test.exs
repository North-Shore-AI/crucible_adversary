defmodule CrucibleAdversary.Metrics.CertifiedTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Metrics.Certified

  # Simple test model for certification
  defmodule TestModel do
    def predict(input) do
      cond do
        String.contains?(input, "positive") -> {:ok, :positive}
        String.contains?(input, "negative") -> {:ok, :negative}
        true -> {:ok, :neutral}
      end
    end
  end

  describe "randomized_smoothing/3" do
    test "computes certification radius with default options" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "positive example",
          []
        )

      assert is_float(result.certified_radius)
      assert result.certified_radius >= 0.0
      assert is_float(result.confidence)
      assert result.confidence >= 0.0 and result.confidence <= 1.0
      assert result.base_prediction in [:positive, :negative, :neutral]
      assert result.certification_level in [:none, :low, :medium, :high]
    end

    test "respects num_samples option" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "test input",
          num_samples: 50
        )

      assert result.num_samples == 50
    end

    test "uses noise_std parameter" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "test",
          noise_std: 0.2
        )

      assert result.noise_std == 0.2
    end

    test "classifies certification levels correctly" do
      # High confidence should give better certification
      {:ok, result_high} =
        Certified.randomized_smoothing(
          TestModel,
          "very positive example with positive words",
          num_samples: 100
        )

      assert result_high.certification_level != :none
    end

    test "handles model with function interface" do
      model_fn = fn input ->
        if String.length(input) > 5 do
          {:ok, :long}
        else
          {:ok, :short}
        end
      end

      {:ok, result} =
        Certified.randomized_smoothing(
          model_fn,
          "test input",
          num_samples: 20
        )

      assert is_map(result)
      assert result.base_prediction in [:long, :short]
    end

    test "includes statistical metadata" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "positive",
          num_samples: 30
        )

      assert Map.has_key?(result, :prediction_counts)
      assert is_map(result.prediction_counts)
      assert Map.has_key?(result, :majority_proportion)
      assert is_float(result.majority_proportion)
    end
  end

  describe "certification_level/1" do
    test "classifies high confidence" do
      assert Certified.certification_level(0.95) == :high
      assert Certified.certification_level(0.90) == :high
    end

    test "classifies medium confidence" do
      assert Certified.certification_level(0.75) == :medium
      assert Certified.certification_level(0.70) == :medium
    end

    test "classifies low confidence" do
      assert Certified.certification_level(0.60) == :low
      assert Certified.certification_level(0.55) == :low
    end

    test "classifies no certification" do
      assert Certified.certification_level(0.45) == :none
      assert Certified.certification_level(0.30) == :none
    end
  end

  describe "compute_radius/2" do
    test "computes radius from confidence" do
      radius = Certified.compute_radius(0.9, 0.1)

      assert is_float(radius)
      assert radius >= 0.0
    end

    test "higher confidence gives larger radius" do
      radius_high = Certified.compute_radius(0.95, 0.1)
      radius_low = Certified.compute_radius(0.60, 0.1)

      assert radius_high >= radius_low
    end

    test "noise level affects radius" do
      radius_low_noise = Certified.compute_radius(0.8, 0.05)
      radius_high_noise = Certified.compute_radius(0.8, 0.2)

      # Lower noise typically gives smaller certified radius
      assert is_float(radius_low_noise)
      assert is_float(radius_high_noise)
    end
  end

  describe "certified_accuracy/3" do
    test "computes certified accuracy on test set" do
      test_set = [
        {"positive test", :positive},
        {"negative test", :negative},
        {"positive again", :positive}
      ]

      {:ok, accuracy} =
        Certified.certified_accuracy(
          TestModel,
          test_set,
          radius: 0.5,
          num_samples: 20
        )

      assert is_float(accuracy)
      assert accuracy >= 0.0 and accuracy <= 1.0
    end

    test "includes per-example certification" do
      test_set = [{"positive", :positive}]

      {:ok, accuracy, details} =
        Certified.certified_accuracy(
          TestModel,
          test_set,
          radius: 0.3,
          num_samples: 10,
          return_details: true
        )

      assert is_float(accuracy)
      assert is_list(details)
      assert length(details) == 1

      detail = List.first(details)
      assert Map.has_key?(detail, :input)
      assert Map.has_key?(detail, :certified)
      assert Map.has_key?(detail, :prediction)
    end

    test "respects radius threshold" do
      test_set = [{"test", :neutral}]

      {:ok, acc_small} =
        Certified.certified_accuracy(
          TestModel,
          test_set,
          radius: 0.1,
          num_samples: 20
        )

      {:ok, acc_large} =
        Certified.certified_accuracy(
          TestModel,
          test_set,
          radius: 1.0,
          num_samples: 20
        )

      # Larger radius is harder to certify
      assert acc_small >= acc_large
    end
  end

  describe "edge cases" do
    test "handles empty string input" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "",
          num_samples: 10
        )

      assert is_map(result)
      assert result.certified_radius >= 0.0
    end

    test "handles very short inputs" do
      {:ok, result} =
        Certified.randomized_smoothing(
          TestModel,
          "a",
          num_samples: 10
        )

      assert is_map(result)
    end

    test "handles inconsistent model predictions" do
      inconsistent_model = fn _input ->
        # Random prediction
        {:ok, Enum.random([:a, :b, :c, :d, :e])}
      end

      {:ok, result} =
        Certified.randomized_smoothing(
          inconsistent_model,
          "test",
          num_samples: 20
        )

      # Should have low confidence and certification
      assert result.confidence < 0.7
      assert result.certification_level in [:none, :low]
    end
  end
end
