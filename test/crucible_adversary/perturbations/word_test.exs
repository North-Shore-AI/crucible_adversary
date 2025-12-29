defmodule CrucibleAdversary.Perturbations.WordTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Perturbations.Word

  describe "delete/2" do
    test "deletes words at specified rate" do
      input = "the quick brown fox jumps over the lazy dog"

      {:ok, result} = Word.delete(input, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :word_deletion
      assert result.attacked != input
      assert result.success == true
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Word.delete("test", rate: 1.5)
    end

    test "handles empty string" do
      {:ok, result} = Word.delete("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "handles single word" do
      {:ok, result} = Word.delete("hello", rate: 0.5, seed: 42)
      assert %AttackResult{} = result
    end

    test "preserves stopwords when option set" do
      {:ok, result} =
        Word.delete("the cat sat on the mat", rate: 0.5, seed: 42, preserve_stopwords: true)

      # Should preserve common words like "the", "on"
      assert %AttackResult{} = result
    end

    test "reproducible with seed" do
      {:ok, result1} = Word.delete("hello world test", rate: 0.3, seed: 100)
      {:ok, result2} = Word.delete("hello world test", rate: 0.3, seed: 100)
      assert result1.attacked == result2.attacked
    end
  end

  describe "insert/2" do
    test "inserts words at specified rate" do
      input = "hello world"

      {:ok, result} = Word.insert(input, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :word_insertion
      # Should have more words
      assert length(String.split(result.attacked)) >= length(String.split(input))
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Word.insert("test", rate: -0.1)
    end

    test "handles empty string" do
      {:ok, result} = Word.insert("", rate: 0.5, seed: 42)
      assert %AttackResult{} = result
    end

    test "uses custom dictionary when provided" do
      {:ok, result} = Word.insert("test", rate: 0.5, seed: 42, dictionary: ["foo", "bar"])
      assert %AttackResult{} = result
    end

    test "uses random noise type" do
      {:ok, result} = Word.insert("test", rate: 0.3, seed: 42, noise_type: :random_words)
      assert %AttackResult{} = result
    end
  end

  describe "synonym_replace/2" do
    test "replaces words with synonyms" do
      input = "the quick brown fox"

      {:ok, result} = Word.synonym_replace(input, rate: 0.5, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :synonym_replacement
      # Should have same number of words
      assert length(String.split(result.attacked)) == length(String.split(input))
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Word.synonym_replace("test", rate: 2.0)
    end

    test "handles empty string" do
      {:ok, result} = Word.synonym_replace("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "handles words with no synonyms" do
      {:ok, result} = Word.synonym_replace("xyz abc", rate: 1.0)
      # Words without synonyms remain unchanged
      assert %AttackResult{} = result
    end

    test "uses specified dictionary" do
      {:ok, result} = Word.synonym_replace("test", rate: 0.5, seed: 42, dictionary: :simple)
      assert %AttackResult{} = result
    end

    test "reproducible with seed" do
      {:ok, result1} = Word.synonym_replace("quick dangerous", rate: 0.5, seed: 100)
      {:ok, result2} = Word.synonym_replace("quick dangerous", rate: 0.5, seed: 100)
      assert result1.attacked == result2.attacked
    end
  end

  describe "shuffle/2" do
    test "shuffles word order" do
      input = "the quick brown fox jumps"

      {:ok, result} = Word.shuffle(input, rate: 0.5, seed: 42)

      assert %AttackResult{} = result
      assert result.original == input
      assert result.attack_type == :word_shuffle
      # Same words, potentially different order
      assert length(String.split(result.attacked)) == length(String.split(input))
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Word.shuffle("test", rate: 1.1)
    end

    test "handles empty string" do
      {:ok, result} = Word.shuffle("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "handles single word" do
      {:ok, result} = Word.shuffle("hello", rate: 0.5)
      assert result.attacked == "hello"
      assert result.success == false
    end

    test "uses adjacent_only shuffle type" do
      {:ok, result} =
        Word.shuffle("one two three four", rate: 0.5, seed: 42, shuffle_type: :adjacent_only)

      assert %AttackResult{} = result
    end

    test "uses random shuffle type" do
      {:ok, result} =
        Word.shuffle("one two three four", rate: 0.5, seed: 42, shuffle_type: :random)

      assert %AttackResult{} = result
    end

    test "reproducible with seed" do
      {:ok, result1} = Word.shuffle("one two three four", rate: 0.5, seed: 100)
      {:ok, result2} = Word.shuffle("one two three four", rate: 0.5, seed: 100)
      assert result1.attacked == result2.attacked
    end
  end
end
