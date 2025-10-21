defmodule CrucibleAdversary.Metrics.ConsistencyTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Metrics.Consistency

  describe "semantic_similarity/3" do
    test "calculates Jaccard similarity" do
      text1 = "the cat sat on the mat"
      text2 = "the cat sat on the rug"

      similarity = Consistency.semantic_similarity(text1, text2, method: :jaccard)

      # 5 words in common (the, cat, sat, on, the) out of 7 total unique words
      # Jaccard = 5/7 ≈ 0.714, but "the" appears twice, so it's actually 4/6 ≈ 0.667
      assert similarity > 0.6
      assert similarity < 1.0
    end

    test "returns 1.0 for identical texts" do
      text = "hello world"

      similarity = Consistency.semantic_similarity(text, text, method: :jaccard)

      assert similarity == 1.0
    end

    test "returns 0.0 for completely different texts" do
      text1 = "hello world"
      text2 = "foo bar"

      similarity = Consistency.semantic_similarity(text1, text2, method: :jaccard)

      assert similarity == 0.0
    end

    test "calculates edit distance similarity" do
      text1 = "hello"
      text2 = "hallo"

      similarity = Consistency.semantic_similarity(text1, text2, method: :edit_distance)

      assert similarity >= 0.8
      assert similarity < 1.0
    end

    test "handles empty strings" do
      similarity = Consistency.semantic_similarity("", "", method: :jaccard)
      assert similarity == 1.0
    end

    test "uses default method (jaccard)" do
      text1 = "test"
      text2 = "test"

      similarity = Consistency.semantic_similarity(text1, text2)

      assert similarity == 1.0
    end
  end

  describe "consistency/3" do
    test "calculates consistency statistics" do
      original_outputs = ["hello world", "test input", "another example"]
      perturbed_outputs = ["hello worl", "test inpu", "another example"]

      result =
        Consistency.consistency(original_outputs, perturbed_outputs, method: :edit_distance)

      assert result.mean_consistency > 0.8
      assert result.mean_consistency <= 1.0
      assert result.min >= 0.0
      assert result.max <= 1.0
      assert Map.has_key?(result, :median_consistency)
      assert Map.has_key?(result, :std_consistency)
    end

    test "handles perfect consistency" do
      outputs = ["test", "example"]

      result = Consistency.consistency(outputs, outputs)

      assert result.mean_consistency == 1.0
      assert result.min == 1.0
      assert result.max == 1.0
      assert result.std_consistency == 0.0
    end

    test "handles empty lists" do
      result = Consistency.consistency([], [])

      assert result.mean_consistency == 0.0
      assert result.min == 0.0
      assert result.max == 0.0
    end
  end
end
