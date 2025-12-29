defmodule CrucibleAdversary.CoreTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Config
  alias CrucibleAdversary.EvaluationResult

  describe "AttackResult" do
    test "creates struct with default values" do
      result = %AttackResult{
        original: "test",
        attacked: "tset",
        attack_type: :character_swap
      }

      assert result.original == "test"
      assert result.attacked == "tset"
      assert result.attack_type == :character_swap
      assert result.success == false
      assert result.metadata == %{}
      assert is_nil(result.timestamp)
    end

    test "creates struct with all values" do
      timestamp = DateTime.utc_now()

      result = %AttackResult{
        original: "hello",
        attacked: "hlelo",
        attack_type: :character_swap,
        success: true,
        metadata: %{rate: 0.2},
        timestamp: timestamp
      }

      assert result.original == "hello"
      assert result.attacked == "hlelo"
      assert result.attack_type == :character_swap
      assert result.success == true
      assert result.metadata == %{rate: 0.2}
      assert result.timestamp == timestamp
    end
  end

  describe "EvaluationResult" do
    test "creates struct with default values" do
      result = %EvaluationResult{
        model: :test_model,
        test_set_size: 100
      }

      assert result.model == :test_model
      assert result.test_set_size == 100
      assert result.attack_types == []
      assert result.metrics == %{}
      assert result.vulnerabilities == []
      assert is_nil(result.timestamp)
    end

    test "creates struct with all values" do
      timestamp = DateTime.utc_now()

      result = %EvaluationResult{
        model: "MyModel",
        test_set_size: 50,
        attack_types: [:character_swap, :word_deletion],
        metrics: %{accuracy_drop: 0.15},
        vulnerabilities: [%{type: :high_asr, details: "..."}],
        timestamp: timestamp
      }

      assert result.model == "MyModel"
      assert result.test_set_size == 50
      assert result.attack_types == [:character_swap, :word_deletion]
      assert result.metrics == %{accuracy_drop: 0.15}
      assert length(result.vulnerabilities) == 1
      assert result.timestamp == timestamp
    end
  end

  describe "Config" do
    test "creates default configuration" do
      config = Config.default()

      assert config.default_attack_rate == 0.1
      assert config.max_perturbation_rate == 0.3
      assert is_nil(config.random_seed)
      assert config.logging_level == :info
      assert config.cache_enabled == true
    end

    test "validates valid configuration" do
      config = %Config{
        default_attack_rate: 0.15,
        max_perturbation_rate: 0.4,
        random_seed: 42,
        logging_level: :debug,
        cache_enabled: false
      }

      assert Config.validate(config) == :ok
    end

    test "validates invalid attack rate - too low" do
      config = %Config{default_attack_rate: -0.1}
      assert Config.validate(config) == {:error, :invalid_attack_rate}
    end

    test "validates invalid attack rate - too high" do
      config = %Config{default_attack_rate: 1.5}
      assert Config.validate(config) == {:error, :invalid_attack_rate}
    end

    test "validates invalid max perturbation rate" do
      config = %Config{max_perturbation_rate: -0.1}
      assert Config.validate(config) == {:error, :invalid_max_perturbation_rate}
    end

    test "validates invalid logging level" do
      config = %Config{logging_level: :invalid}
      assert Config.validate(config) == {:error, :invalid_logging_level}
    end
  end
end
