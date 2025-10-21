defmodule CrucibleAdversary.Perturbations.SemanticTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Perturbations.Semantic
  alias CrucibleAdversary.AttackResult

  describe "paraphrase/2" do
    test "paraphrases text while preserving meaning" do
      input = "The quick brown fox jumps over the lazy dog"

      {:ok, result} = Semantic.paraphrase(input, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :semantic_paraphrase
      assert result.attacked != input
      assert result.success == true
    end

    test "uses different paraphrase strategies" do
      input = "This is a test"

      {:ok, result} = Semantic.paraphrase(input, strategy: :simple, seed: 42)

      assert %AttackResult{} = result
      assert result.metadata.strategy == :simple
    end

    test "handles empty string" do
      {:ok, result} = Semantic.paraphrase("")

      assert result.attacked == ""
      assert result.success == false
    end

    test "handles short text" do
      {:ok, result} = Semantic.paraphrase("Hello", seed: 42)

      assert %AttackResult{} = result
    end

    test "reproducible with seed" do
      {:ok, result1} = Semantic.paraphrase("test input", seed: 100)
      {:ok, result2} = Semantic.paraphrase("test input", seed: 100)

      assert result1.attacked == result2.attacked
    end
  end

  describe "back_translate/2" do
    test "simulates back-translation artifacts" do
      input = "The cat sat on the mat"

      {:ok, result} = Semantic.back_translate(input, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :semantic_back_translate
      # Should have some changes from translation artifacts
      assert result.attacked != input or String.length(input) < 10
    end

    test "uses specified intermediate language" do
      {:ok, result} = Semantic.back_translate("test", intermediate: :spanish, seed: 42)

      assert result.metadata.intermediate == :spanish
    end

    test "handles empty string" do
      {:ok, result} = Semantic.back_translate("")

      assert result.attacked == ""
      assert result.success == false
    end

    test "reproducible with seed" do
      {:ok, result1} = Semantic.back_translate("hello world", seed: 100)
      {:ok, result2} = Semantic.back_translate("hello world", seed: 100)

      assert result1.attacked == result2.attacked
    end
  end

  describe "sentence_reorder/2" do
    test "reorders sentences in text" do
      input = "First sentence. Second sentence. Third sentence."

      {:ok, result} = Semantic.sentence_reorder(input, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :semantic_sentence_reorder
      # Same sentences, potentially different order
      assert String.contains?(result.attacked, "First sentence")
      assert String.contains?(result.attacked, "Second sentence")
    end

    test "handles single sentence" do
      {:ok, result} = Semantic.sentence_reorder("Only one sentence.", seed: 42)

      assert result.attacked == "Only one sentence."
      assert result.success == false
    end

    test "handles empty string" do
      {:ok, result} = Semantic.sentence_reorder("")

      assert result.attacked == ""
      assert result.success == false
    end

    test "reproducible with seed" do
      input = "A. B. C."
      {:ok, result1} = Semantic.sentence_reorder(input, seed: 100)
      {:ok, result2} = Semantic.sentence_reorder(input, seed: 100)

      assert result1.attacked == result2.attacked
    end
  end

  describe "formality_change/2" do
    test "changes text formality level" do
      input = "Hello, how are you doing today?"

      {:ok, result} = Semantic.formality_change(input, direction: :informal, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :semantic_formality_change
      assert result.metadata.direction == :informal
    end

    test "formalizes informal text" do
      input = "hey whats up"

      {:ok, result} = Semantic.formality_change(input, direction: :formal, seed: 42)

      assert %AttackResult{} = result
      assert result.metadata.direction == :formal
    end

    test "handles empty string" do
      {:ok, result} = Semantic.formality_change("")

      assert result.attacked == ""
      assert result.success == false
    end

    test "uses default direction" do
      {:ok, result} = Semantic.formality_change("test", seed: 42)

      assert Map.has_key?(result.metadata, :direction)
    end
  end
end
