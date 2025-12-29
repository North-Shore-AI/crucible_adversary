defmodule CrucibleAdversary.Attacks.InversionTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Attacks.Inversion

  doctest Inversion

  # Simple test model for membership inference
  defmodule TestModel do
    def predict("training_example_1"), do: {:ok, %{confidence: 0.95, prediction: :positive}}
    def predict("training_example_2"), do: {:ok, %{confidence: 0.92, prediction: :negative}}
    def predict("non_training_example"), do: {:ok, %{confidence: 0.65, prediction: :neutral}}
    def predict(_), do: {:ok, %{confidence: 0.70, prediction: :unknown}}
  end

  describe "membership_inference/3" do
    test "infers membership for training examples" do
      {:ok, result} =
        Inversion.membership_inference(
          TestModel,
          "training_example_1",
          []
        )

      assert %AttackResult{} = result
      assert result.attack_type == :model_inversion_membership
      assert result.success == true
      assert result.metadata.is_member == true
      assert result.metadata.confidence > 0.5
    end

    test "infers non-membership correctly" do
      {:ok, result} =
        Inversion.membership_inference(
          TestModel,
          "non_training_example",
          []
        )

      assert result.metadata.is_member == false
      assert result.metadata.confidence >= 0.0
    end

    test "includes confidence threshold in metadata" do
      {:ok, result} =
        Inversion.membership_inference(
          TestModel,
          "test_input",
          confidence_threshold: 0.8
        )

      assert result.metadata.confidence_threshold == 0.8
    end

    test "supports statistical testing" do
      {:ok, result} =
        Inversion.membership_inference(
          TestModel,
          "training_example_1",
          statistical_test: true
        )

      assert result.metadata.statistical_test == true
      assert is_map(result.metadata.test_results)
    end

    test "handles model with function interface" do
      model_fn = fn input ->
        if input == "member", do: {:ok, %{confidence: 0.99}}, else: {:ok, %{confidence: 0.60}}
      end

      {:ok, result} = Inversion.membership_inference(model_fn, "member", [])

      assert result.metadata.is_member == true
    end
  end

  describe "attribute_inference/3" do
    test "infers attributes from model behavior" do
      {:ok, result} =
        Inversion.attribute_inference(
          TestModel,
          "training_example_1",
          attributes: [:sentiment, :topic]
        )

      assert %AttackResult{} = result
      assert result.attack_type == :model_inversion_attribute
      assert result.success == true
      assert is_map(result.metadata.inferred_attributes)
    end

    test "respects specified attributes" do
      {:ok, result} =
        Inversion.attribute_inference(
          TestModel,
          "test",
          attributes: [:category, :language]
        )

      assert result.metadata.target_attributes == [:category, :language]
      assert Map.has_key?(result.metadata.inferred_attributes, :category)
      assert Map.has_key?(result.metadata.inferred_attributes, :language)
    end

    test "includes inference confidence scores" do
      {:ok, result} =
        Inversion.attribute_inference(
          TestModel,
          "test",
          attributes: [:sentiment]
        )

      inferred = result.metadata.inferred_attributes
      assert Map.has_key?(inferred, :sentiment)
      assert is_map(inferred[:sentiment])
      assert Map.has_key?(inferred[:sentiment], :value)
      assert Map.has_key?(inferred[:sentiment], :confidence)
    end

    test "supports multiple probing strategies" do
      {:ok, result} =
        Inversion.attribute_inference(
          TestModel,
          "test",
          attributes: [:type],
          strategy: :perturbation
        )

      assert result.metadata.strategy == :perturbation
    end
  end

  describe "reconstruction_attack/3" do
    test "attempts to reconstruct training features" do
      {:ok, result} =
        Inversion.reconstruction_attack(
          TestModel,
          target: "hidden_features",
          method: :gradient_approximation
        )

      assert %AttackResult{} = result
      assert result.attack_type == :model_inversion_reconstruction
      assert result.success == true
    end

    test "includes reconstruction quality metric" do
      {:ok, result} =
        Inversion.reconstruction_attack(
          TestModel,
          target: "features",
          method: :output_analysis
        )

      assert is_float(result.metadata.reconstruction_quality)
      assert result.metadata.reconstruction_quality >= 0.0
      assert result.metadata.reconstruction_quality <= 1.0
    end

    test "supports different reconstruction methods" do
      methods = [:gradient_approximation, :output_analysis, :query_based]

      for method <- methods do
        {:ok, result} =
          Inversion.reconstruction_attack(
            TestModel,
            target: "test",
            method: method
          )

        assert result.metadata.method == method
      end
    end

    test "includes number of queries used" do
      {:ok, result} =
        Inversion.reconstruction_attack(
          TestModel,
          target: "test",
          max_queries: 100
        )

      assert is_integer(result.metadata.queries_used)
      assert result.metadata.queries_used <= 100
    end
  end

  describe "property_inference/3" do
    test "infers dataset properties" do
      {:ok, result} =
        Inversion.property_inference(
          TestModel,
          property: :class_distribution,
          samples: 10
        )

      assert %AttackResult{} = result
      assert result.attack_type == :model_inversion_property
      assert result.success == true
    end

    test "supports different property types" do
      properties = [:class_distribution, :feature_correlation, :data_balance]

      for property <- properties do
        {:ok, result} =
          Inversion.property_inference(
            TestModel,
            property: property,
            samples: 5
          )

        assert result.metadata.property_type == property
      end
    end

    test "includes statistical confidence" do
      {:ok, result} =
        Inversion.property_inference(
          TestModel,
          property: :class_distribution,
          samples: 20
        )

      assert is_map(result.metadata.inferred_property)
      assert Map.has_key?(result.metadata, :statistical_confidence)
    end
  end

  describe "integration" do
    test "all inversion attacks return valid AttackResult" do
      {:ok, r1} = Inversion.membership_inference(TestModel, "test", [])
      {:ok, r2} = Inversion.attribute_inference(TestModel, "test", attributes: [:type])

      {:ok, r3} =
        Inversion.reconstruction_attack(TestModel, target: "test", method: :output_analysis)

      {:ok, r4} =
        Inversion.property_inference(TestModel, property: :class_distribution, samples: 5)

      for result <- [r1, r2, r3, r4] do
        assert %AttackResult{} = result
        assert result.success == true
        assert is_atom(result.attack_type)
        assert String.starts_with?(Atom.to_string(result.attack_type), "model_inversion_")
        assert %DateTime{} = result.timestamp
        assert is_map(result.metadata)
      end
    end

    test "inversion attacks have unique types" do
      {:ok, r1} = Inversion.membership_inference(TestModel, "test", [])
      {:ok, r2} = Inversion.attribute_inference(TestModel, "test", attributes: [:type])

      {:ok, r3} =
        Inversion.reconstruction_attack(TestModel, target: "test", method: :output_analysis)

      {:ok, r4} =
        Inversion.property_inference(TestModel, property: :class_distribution, samples: 5)

      types = [r1.attack_type, r2.attack_type, r3.attack_type, r4.attack_type]
      assert length(Enum.uniq(types)) == 4
    end
  end
end
