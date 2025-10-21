defmodule CrucibleAdversaryAPITest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.{AttackResult, EvaluationResult}

  describe "attack/2" do
    test "performs character swap attack" do
      {:ok, result} =
        CrucibleAdversary.attack("hello world", type: :character_swap, rate: 0.2, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "hello world"
      assert result.attack_type == :character_swap
    end

    test "performs word deletion attack" do
      {:ok, result} =
        CrucibleAdversary.attack("hello world test", type: :word_deletion, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.attack_type == :word_deletion
    end

    test "performs homoglyph attack" do
      {:ok, result} = CrucibleAdversary.attack("test", type: :homoglyph, rate: 0.5, seed: 42)

      assert %AttackResult{} = result
      assert result.attack_type == :homoglyph
    end

    test "returns error for unknown attack type" do
      assert {:error, {:unknown_attack_type, :invalid_type}} =
               CrucibleAdversary.attack("test", type: :invalid_type)
    end

    test "returns error for missing type" do
      assert_raise KeyError, fn ->
        CrucibleAdversary.attack("test", rate: 0.1)
      end
    end
  end

  describe "attack_batch/2" do
    test "performs attacks on multiple inputs" do
      inputs = ["hello world", "test input", "another example"]

      {:ok, results} = CrucibleAdversary.attack_batch(inputs, types: [:character_swap], seed: 42)

      assert is_list(results)
      assert length(results) == 3
      assert Enum.all?(results, fn r -> match?(%AttackResult{}, r) end)
    end

    test "uses default attack type when not specified" do
      {:ok, results} = CrucibleAdversary.attack_batch(["test"], seed: 42)

      assert is_list(results)
      assert length(results) > 0
    end

    test "handles empty input list" do
      {:ok, results} = CrucibleAdversary.attack_batch([])

      assert results == []
    end

    test "performs multiple attack types per input" do
      {:ok, results} =
        CrucibleAdversary.attack_batch(
          ["test"],
          types: [:character_swap, :word_deletion],
          seed: 42
        )

      assert length(results) == 2
    end
  end

  describe "evaluate/3" do
    test "evaluates model robustness" do
      model = fn input -> String.upcase(input) end
      test_set = [{"hello", "HELLO"}, {"world", "WORLD"}]

      {:ok, result} = CrucibleAdversary.evaluate(model, test_set, seed: 42)

      assert %EvaluationResult{} = result
      assert result.test_set_size == 2
      assert length(result.attack_types) > 0
      assert map_size(result.metrics) > 0
    end

    test "passes options to Robustness.evaluate" do
      model = fn input -> input end
      test_set = [{"test", "test"}]

      {:ok, result} =
        CrucibleAdversary.evaluate(
          model,
          test_set,
          attacks: [:character_swap],
          metrics: [:asr],
          seed: 42
        )

      assert %EvaluationResult{} = result
      assert :character_swap in result.attack_types
      assert Map.has_key?(result.metrics, :asr)
    end
  end

  describe "config/0 and configure/1" do
    test "returns configuration" do
      config = CrucibleAdversary.config()

      assert is_float(config.default_attack_rate)
      assert is_float(config.max_perturbation_rate)
    end

    test "sets configuration from struct" do
      # Save original
      original = CrucibleAdversary.config()

      new_config = %CrucibleAdversary.Config{
        default_attack_rate: 0.15,
        random_seed: 123
      }

      :ok = CrucibleAdversary.configure(new_config)
      config = CrucibleAdversary.config()

      assert config.default_attack_rate == 0.15
      assert config.random_seed == 123

      # Restore original
      :ok = CrucibleAdversary.configure(original)
    end

    test "sets configuration from keyword list" do
      # Save original
      original = CrucibleAdversary.config()

      :ok = CrucibleAdversary.configure(default_attack_rate: 0.2)
      config = CrucibleAdversary.config()

      assert config.default_attack_rate == 0.2

      # Restore original
      :ok = CrucibleAdversary.configure(original)
    end
  end

  describe "version/0" do
    test "returns version string" do
      version = CrucibleAdversary.version()

      assert is_binary(version)
      assert version =~ ~r/\d+\.\d+\.\d+/
    end
  end
end
