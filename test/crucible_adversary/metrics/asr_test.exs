defmodule CrucibleAdversary.Metrics.ASRTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.{AttackResult, Metrics.ASR}

  describe "calculate/2" do
    test "calculates overall attack success rate" do
      attack_results = [
        %AttackResult{attack_type: :character_swap, success: true, original: "a", attacked: "b"},
        %AttackResult{attack_type: :character_swap, success: false, original: "c", attacked: "c"},
        %AttackResult{attack_type: :word_deletion, success: true, original: "d", attacked: "e"},
        %AttackResult{attack_type: :word_deletion, success: true, original: "f", attacked: "g"}
      ]

      success_fn = fn result -> result.success end
      result = ASR.calculate(attack_results, success_fn)

      assert result.overall_asr == 0.75
      assert result.total_attacks == 4
      assert result.successful_attacks == 3
      assert result.by_attack_type.character_swap == 0.5
      assert result.by_attack_type.word_deletion == 1.0
    end

    test "handles all successful attacks" do
      attack_results = [
        %AttackResult{attack_type: :character_swap, success: true, original: "a", attacked: "b"},
        %AttackResult{attack_type: :character_swap, success: true, original: "c", attacked: "d"}
      ]

      success_fn = fn result -> result.success end
      result = ASR.calculate(attack_results, success_fn)

      assert result.overall_asr == 1.0
      assert result.total_attacks == 2
      assert result.successful_attacks == 2
    end

    test "handles no successful attacks" do
      attack_results = [
        %AttackResult{attack_type: :character_swap, success: false, original: "a", attacked: "a"}
      ]

      success_fn = fn result -> result.success end
      result = ASR.calculate(attack_results, success_fn)

      assert result.overall_asr == 0.0
      assert result.successful_attacks == 0
    end

    test "handles empty results" do
      success_fn = fn result -> result.success end
      result = ASR.calculate([], success_fn)

      assert result.overall_asr == 0.0
      assert result.total_attacks == 0
      assert result.successful_attacks == 0
    end

    test "uses custom success function" do
      attack_results = [
        %AttackResult{
          attack_type: :character_swap,
          metadata: %{confidence: 0.9},
          original: "a",
          attacked: "b"
        },
        %AttackResult{
          attack_type: :character_swap,
          metadata: %{confidence: 0.3},
          original: "c",
          attacked: "d"
        }
      ]

      success_fn = fn result -> result.metadata[:confidence] > 0.5 end
      result = ASR.calculate(attack_results, success_fn)

      assert result.overall_asr == 0.5
    end
  end

  describe "query_efficiency/2" do
    test "calculates query efficiency" do
      attack_results = [
        %{success: true, queries: 5},
        %{success: true, queries: 10},
        %{success: false, queries: 15}
      ]

      result = ASR.query_efficiency(attack_results, 30)

      assert result.total_queries == 30
      assert result.successful_attacks == 2
      assert_in_delta result.efficiency, 0.0667, 0.001
      assert result.avg_queries_per_success == 7.5
    end

    test "handles zero queries" do
      result = ASR.query_efficiency([], 0)

      assert result.total_queries == 0
      assert result.successful_attacks == 0
      assert result.efficiency == 0.0
    end
  end
end
