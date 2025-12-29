defmodule CrucibleAdversary.CompositionTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Composition

  describe "chain/2" do
    test "creates attack chain with multiple attacks" do
      chain =
        Composition.chain([
          {:character_swap, rate: 0.1},
          {:word_deletion, rate: 0.2}
        ])

      assert is_list(chain)
      assert length(chain) == 2
    end

    test "executes chain on input" do
      chain =
        Composition.chain([
          {:character_swap, rate: 0.1, seed: 42},
          {:word_insertion, rate: 0.1, seed: 42}
        ])

      {:ok, result} = Composition.execute(chain, "Test input text")

      assert %AttackResult{} = result
      assert result.attack_type == :composition_chain
      assert is_list(result.metadata.intermediate_results)
      assert length(result.metadata.intermediate_results) == 2
    end

    test "chain preserves attack order" do
      chain =
        Composition.chain([
          {:character_swap, rate: 0.1},
          {:semantic_paraphrase, []},
          {:prompt_injection_basic, payload: "Test"}
        ])

      {:ok, result} = Composition.execute(chain, "Input")

      intermediates = result.metadata.intermediate_results
      assert length(intermediates) == 3

      types = Enum.map(intermediates, & &1.attack_type)
      assert types == [:character_swap, :semantic_paraphrase, :prompt_injection_basic]
    end

    test "final output is result of last attack in chain" do
      {:ok, result} =
        Composition.execute(
          [{:character_swap, rate: 0.2, seed: 42}],
          "test"
        )

      last_intermediate = List.last(result.metadata.intermediate_results)
      assert result.attacked == last_intermediate.attacked
    end
  end

  describe "parallel/2" do
    test "creates parallel attack specification" do
      parallel =
        Composition.parallel([
          {:character_swap, rate: 0.1},
          {:word_deletion, rate: 0.2},
          {:synonym_replacement, rate: 0.1}
        ])

      assert is_list(parallel)
      assert length(parallel) == 3
    end

    test "executes all attacks in parallel" do
      parallel =
        Composition.parallel([
          {:character_swap, rate: 0.1, seed: 42},
          {:word_deletion, rate: 0.2, seed: 42}
        ])

      {:ok, results} = Composition.execute_parallel(parallel, "Test input")

      assert is_list(results)
      assert length(results) == 2
      assert Enum.all?(results, &match?(%AttackResult{}, &1))
    end

    test "parallel results contain all attack types" do
      {:ok, results} =
        Composition.execute_parallel(
          [
            {:character_swap, []},
            {:word_shuffle, []}
          ],
          "input"
        )

      types = Enum.map(results, & &1.attack_type)
      assert :character_swap in types
      assert :word_shuffle in types
    end
  end

  describe "best_of/3" do
    test "selects best result from parallel attacks" do
      attacks = [
        {:character_swap, rate: 0.1, seed: 42},
        {:character_swap, rate: 0.3, seed: 43}
      ]

      selector = fn results ->
        # Select attack with longest output
        Enum.max_by(results, fn r -> String.length(r.attacked) end)
      end

      {:ok, best} = Composition.best_of(attacks, "Input text", selector)

      assert %AttackResult{} = best
      assert best.attack_type == :character_swap
    end

    test "uses default selector if none provided" do
      {:ok, result} =
        Composition.best_of(
          [{:character_swap, []}, {:word_deletion, []}],
          "test input"
        )

      assert %AttackResult{} = result
    end
  end

  describe "conditional/3" do
    test "executes attack if condition is true" do
      condition = fn input -> String.length(input) > 5 end

      {:ok, result} =
        Composition.conditional(
          {:character_swap, rate: 0.1},
          "long input text",
          condition
        )

      assert %AttackResult{} = result
      assert result.attack_type == :character_swap
    end

    test "skips attack if condition is false" do
      condition = fn input -> String.length(input) > 100 end

      {:ok, result} =
        Composition.conditional(
          {:character_swap, rate: 0.1},
          "short",
          condition
        )

      # Should return no-op result
      assert result.original == "short"
      assert result.attacked == "short"
      assert result.metadata.skipped == true
    end
  end

  describe "integration" do
    test "complex composition with chain and conditions" do
      # Create a complex attack strategy
      strategy = [
        {:character_swap, rate: 0.05, seed: 42},
        {:word_deletion, rate: 0.1, seed: 42},
        {:prompt_injection_basic, payload: "Override"}
      ]

      {:ok, result} = Composition.execute(strategy, "This is a test input")

      assert %AttackResult{} = result
      assert result.attack_type == :composition_chain
      assert result.original == "This is a test input"
      assert result.attacked != result.original
      assert length(result.metadata.intermediate_results) == 3
    end

    test "handles empty chain" do
      {:ok, result} = Composition.execute([], "input")

      assert result.original == "input"
      assert result.attacked == "input"
      assert result.metadata.intermediate_results == []
    end

    test "preserves metadata through chain" do
      {:ok, result} =
        Composition.execute(
          [{:character_swap, rate: 0.1, seed: 42}],
          "test"
        )

      intermediate = List.first(result.metadata.intermediate_results)
      assert Map.has_key?(intermediate.metadata, :rate)
      assert intermediate.metadata.rate == 0.1
    end
  end
end
