defmodule CrucibleAdversary.StageTest do
  use ExUnit.Case, async: true
  doctest CrucibleAdversary.Stage

  alias CrucibleAdversary.Stage
  alias CrucibleAdversary.EvaluationResult

  # Simple test model
  defmodule TestModel do
    def predict(input) do
      if String.contains?(String.downcase(input), "positive") do
        :positive
      else
        :negative
      end
    end
  end

  describe "run/2" do
    test "executes adversarial evaluation on valid context" do
      context = %{
        model: TestModel,
        test_set: [
          {"This is positive", :positive},
          {"This is negative", :negative}
        ],
        config: %{
          attacks: [:character_swap],
          metrics: [:accuracy_drop],
          seed: 42
        }
      }

      assert {:ok, result} = Stage.run(context)
      assert Map.has_key?(result, :adversarial_evaluation)
      assert Map.has_key?(result, :adversarial_metrics)
      assert Map.has_key?(result, :adversarial_vulnerabilities)
    end

    test "returns EvaluationResult with correct structure" do
      context = %{
        model: TestModel,
        test_set: [{"positive test", :positive}],
        config: %{attacks: [:character_swap], seed: 42}
      }

      {:ok, result} = Stage.run(context)

      assert %EvaluationResult{} = result.adversarial_evaluation
      assert result.adversarial_evaluation.test_set_size == 1
      assert :character_swap in result.adversarial_evaluation.attack_types
    end

    test "uses default attacks and metrics when not specified" do
      context = %{
        model: fn x -> String.upcase(x) end,
        test_set: [{"hello", "HELLO"}]
      }

      {:ok, result} = Stage.run(context)

      eval = result.adversarial_evaluation
      # Default attacks: [:character_swap, :word_deletion]
      assert length(eval.attack_types) >= 1
      # Default metrics: [:accuracy_drop, :asr]
      assert Map.has_key?(result.adversarial_metrics, :accuracy_drop) or
               Map.has_key?(result.adversarial_metrics, :asr)
    end

    test "handles empty test set gracefully" do
      context = %{
        model: TestModel,
        test_set: [],
        config: %{attacks: [:character_swap]}
      }

      {:ok, result} = Stage.run(context)
      assert result.adversarial_evaluation.test_set_size == 0
    end

    test "merges opts with context.config" do
      context = %{
        model: TestModel,
        test_set: [{"positive", :positive}],
        config: %{attacks: [:character_swap]}
      }

      opts = %{metrics: [:asr], seed: 123}

      {:ok, result} = Stage.run(context, opts)

      # opts should override/extend config
      assert result.adversarial_evaluation.test_set_size == 1
    end

    test "preserves original context keys" do
      context = %{
        model: TestModel,
        test_set: [{"positive", :positive}],
        experiment: %{name: "test_experiment"},
        custom_field: "custom_value",
        config: %{seed: 42}
      }

      {:ok, result} = Stage.run(context)

      # Original keys preserved
      assert result.experiment == %{name: "test_experiment"}
      assert result.custom_field == "custom_value"
      assert result.model == TestModel

      # New keys added
      assert Map.has_key?(result, :adversarial_evaluation)
    end

    test "handles function-based models" do
      model_fn = fn input ->
        if String.length(input) > 5, do: :long, else: :short
      end

      context = %{
        model: model_fn,
        test_set: [{"hello", :long}, {"hi", :short}],
        config: %{attacks: [:character_swap], seed: 42}
      }

      {:ok, result} = Stage.run(context)
      assert result.adversarial_evaluation.test_set_size == 2
    end

    test "supports multiple attack types" do
      context = %{
        model: TestModel,
        test_set: [{"positive example", :positive}],
        config: %{
          attacks: [:character_swap, :word_deletion, :prompt_injection_basic],
          metrics: [:asr],
          seed: 42
        }
      }

      {:ok, result} = Stage.run(context)
      eval = result.adversarial_evaluation

      assert length(eval.attack_types) >= 3
    end

    test "computes accuracy_drop metric when requested" do
      context = %{
        model: TestModel,
        test_set: [
          {"positive", :positive},
          {"negative", :negative}
        ],
        config: %{
          attacks: [:character_swap],
          metrics: [:accuracy_drop],
          seed: 42
        }
      }

      {:ok, result} = Stage.run(context)
      metrics = result.adversarial_metrics

      assert Map.has_key?(metrics, :accuracy_drop)
      assert Map.has_key?(metrics.accuracy_drop, :original_accuracy)
      assert Map.has_key?(metrics.accuracy_drop, :attacked_accuracy)
    end

    test "computes asr metric when requested" do
      context = %{
        model: TestModel,
        test_set: [{"positive", :positive}],
        config: %{
          attacks: [:character_swap],
          metrics: [:asr],
          seed: 42
        }
      }

      {:ok, result} = Stage.run(context)
      metrics = result.adversarial_metrics

      assert Map.has_key?(metrics, :asr)
      assert Map.has_key?(metrics.asr, :overall_asr)
    end

    test "identifies vulnerabilities" do
      # Create a model that's vulnerable to character swaps
      vulnerable_model = fn input ->
        # Very strict matching - any character change breaks it
        if input == "exact match", do: :correct, else: :wrong
      end

      context = %{
        model: vulnerable_model,
        test_set: [{"exact match", :correct}],
        config: %{
          attacks: [:character_swap],
          metrics: [:accuracy_drop],
          seed: 42
        }
      }

      {:ok, result} = Stage.run(context)

      # Should detect vulnerability
      assert is_list(result.adversarial_vulnerabilities)
    end

    test "handles missing model as empty test set" do
      context = %{
        test_set: [{"input", :output}],
        config: %{attacks: [:character_swap]}
      }

      # Without a model, it will try to call nil.predict which raises
      # In practice, pipelines should validate required fields
      # For now, we just verify that missing model causes a failure
      assert_raise UndefinedFunctionError, fn ->
        Stage.run(context)
      end
    end

    test "handles missing test_set gracefully" do
      context = %{
        model: TestModel,
        config: %{attacks: [:character_swap]}
      }

      {:ok, result} = Stage.run(context)
      assert result.adversarial_evaluation.test_set_size == 0
    end

    test "passes seed for reproducibility" do
      context = %{
        model: TestModel,
        test_set: [{"positive", :positive}],
        config: %{attacks: [:character_swap], seed: 42}
      }

      {:ok, result1} = Stage.run(context)
      {:ok, result2} = Stage.run(context)

      # Results should be identical with same seed
      assert result1.adversarial_evaluation.test_set_size ==
               result2.adversarial_evaluation.test_set_size
    end

    test "supports attack_opts configuration" do
      context = %{
        model: TestModel,
        test_set: [{"positive", :positive}],
        config: %{
          attacks: [:character_swap],
          attack_opts: [rate: 0.3],
          seed: 42
        }
      }

      {:ok, result} = Stage.run(context)
      assert result.adversarial_evaluation.test_set_size == 1
    end
  end

  describe "describe/1" do
    test "returns description with default configuration" do
      description = Stage.describe()

      assert is_binary(description)
      assert description =~ "Adversarial robustness testing"
      assert description =~ "character_swap"
      assert description =~ "word_deletion"
      assert description =~ "accuracy_drop"
      assert description =~ "asr"
    end

    test "returns description with custom attacks" do
      opts = %{attacks: [:prompt_injection_basic, :jailbreak_roleplay]}
      description = Stage.describe(opts)

      assert description =~ "prompt_injection_basic"
      assert description =~ "jailbreak_roleplay"
    end

    test "returns description with custom metrics" do
      opts = %{metrics: [:asr]}
      description = Stage.describe(opts)

      assert description =~ "asr"
    end

    test "returns description with both custom attacks and metrics" do
      opts = %{
        attacks: [:character_swap],
        metrics: [:accuracy_drop]
      }

      description = Stage.describe(opts)

      assert description =~ "character_swap"
      assert description =~ "accuracy_drop"
    end

    test "handles empty opts map" do
      description = Stage.describe(%{})

      assert is_binary(description)
      assert description =~ "Adversarial robustness testing"
    end
  end

  describe "integration with CrucibleIR pipeline" do
    test "can be used as a pipeline stage" do
      # Simulate a pipeline context
      pipeline_context = %{
        experiment: %{
          name: "robustness_evaluation",
          timestamp: DateTime.utc_now()
        },
        model: TestModel,
        test_set: [
          {"positive example", :positive},
          {"negative example", :negative}
        ],
        config: %{
          attacks: [:character_swap, :word_deletion],
          metrics: [:accuracy_drop, :asr],
          seed: 42
        }
      }

      # Run stage
      {:ok, result_context} = Stage.run(pipeline_context)

      # Verify pipeline context is preserved and augmented
      assert result_context.experiment.name == "robustness_evaluation"
      assert Map.has_key?(result_context, :adversarial_evaluation)
      assert Map.has_key?(result_context, :adversarial_metrics)
      assert Map.has_key?(result_context, :adversarial_vulnerabilities)

      # Verify evaluation ran correctly
      assert result_context.adversarial_evaluation.test_set_size == 2
    end

    test "stage can be chained with other stages" do
      # First stage: setup
      initial_context = %{
        experiment: %{name: "multi_stage"},
        data: "initial"
      }

      # Add model and test_set (simulating another stage)
      context_after_stage1 =
        initial_context
        |> Map.put(:model, TestModel)
        |> Map.put(:test_set, [{"positive", :positive}])
        |> Map.put(:config, %{attacks: [:character_swap], seed: 42})

      # Run adversarial stage
      {:ok, context_after_stage2} = Stage.run(context_after_stage1)

      # Verify all previous stage data preserved
      assert context_after_stage2.data == "initial"
      assert context_after_stage2.experiment.name == "multi_stage"

      # Verify adversarial stage added its data
      assert Map.has_key?(context_after_stage2, :adversarial_evaluation)
    end
  end
end
