defmodule CrucibleAdversary.Perturbations.CharacterTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Perturbations.Character
  alias CrucibleAdversary.AttackResult

  describe "swap/2" do
    test "swaps adjacent characters at specified rate" do
      input = "hello world"

      {:ok, result} = Character.swap(input, rate: 0.4, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "hello world"
      assert result.attacked != "hello world"
      assert result.attack_type == :character_swap
      assert String.length(result.attacked) == String.length(input)
      assert result.success == true
      assert result.metadata.rate == 0.4
      assert %DateTime{} = result.timestamp
    end

    test "with low rate produces minimal changes" do
      input = "hello"

      {:ok, result} = Character.swap(input, rate: 0.1, seed: 123)

      assert %AttackResult{} = result
      # String length should be preserved
      assert String.length(result.attacked) == String.length(input)
    end

    test "with seed produces reproducible results" do
      input = "test string"

      {:ok, result1} = Character.swap(input, rate: 0.3, seed: 100)
      {:ok, result2} = Character.swap(input, rate: 0.3, seed: 100)

      assert result1.attacked == result2.attacked
    end

    test "returns error for invalid rate - too high" do
      assert {:error, :invalid_rate} = Character.swap("test", rate: 1.5)
    end

    test "returns error for invalid rate - negative" do
      assert {:error, :invalid_rate} = Character.swap("test", rate: -0.1)
    end

    test "handles empty string" do
      {:ok, result} = Character.swap("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "handles single character" do
      {:ok, result} = Character.swap("a", rate: 0.5)
      assert result.attacked == "a"
      assert result.success == false
    end

    test "handles two characters" do
      {:ok, result} = Character.swap("ab", rate: 1.0, seed: 42)
      # Should either swap or not swap
      assert result.attacked in ["ab", "ba"]
    end

    test "uses default rate when not specified" do
      {:ok, result} = Character.swap("hello world", seed: 42)
      assert result.metadata.rate == 0.1
    end

    test "success is false when no swaps occur" do
      # With rate 0, no swaps should occur
      {:ok, result} = Character.swap("hello", rate: 0.0)
      assert result.success == false
      assert result.attacked == "hello"
    end

    test "preserves character composition" do
      input = "hello"
      {:ok, result} = Character.swap(input, rate: 0.5, seed: 42)

      # All characters from original should be present in attacked
      original_chars = String.graphemes(input) |> Enum.sort()
      attacked_chars = String.graphemes(result.attacked) |> Enum.sort()

      assert original_chars == attacked_chars
    end
  end

  describe "delete/2" do
    test "deletes characters at specified rate" do
      input = "hello world"

      {:ok, result} = Character.delete(input, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "hello world"
      assert result.attack_type == :character_delete
      assert String.length(result.attacked) < String.length(input)
      assert result.success == true
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Character.delete("test", rate: 1.5)
    end

    test "handles empty string" do
      {:ok, result} = Character.delete("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "preserves spaces when option set" do
      {:ok, result} = Character.delete("hello world", rate: 0.5, seed: 42, preserve_spaces: true)
      # Space should be preserved
      assert String.contains?(result.attacked, " ")
    end

    test "can delete spaces when option not set" do
      {:ok, result} = Character.delete("hello world", rate: 1.0, seed: 42, preserve_spaces: false)
      # At high rate, likely to delete spaces
      assert %AttackResult{} = result
    end
  end

  describe "insert/2" do
    test "inserts characters at specified rate" do
      input = "hello"

      {:ok, result} = Character.insert(input, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "hello"
      assert result.attack_type == :character_insert
      assert String.length(result.attacked) > String.length(input)
      assert result.success == true
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Character.insert("test", rate: -0.1)
    end

    test "handles empty string" do
      {:ok, result} = Character.insert("", rate: 0.5, seed: 42)
      # Can insert into empty string
      assert %AttackResult{} = result
    end

    test "uses custom character pool when provided" do
      {:ok, result} = Character.insert("test", rate: 0.5, seed: 42, char_pool: ["x", "y", "z"])
      # Inserted characters should be from pool
      assert %AttackResult{} = result
    end
  end

  describe "homoglyph/2" do
    test "substitutes characters with homoglyphs" do
      input = "administrator"

      {:ok, result} = Character.homoglyph(input, rate: 0.3, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "administrator"
      assert result.attack_type == :homoglyph
      # Length should be same (character-for-character substitution)
      assert String.length(result.attacked) == String.length(input)
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Character.homoglyph("test", rate: 2.0)
    end

    test "handles empty string" do
      {:ok, result} = Character.homoglyph("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "uses specified charset" do
      {:ok, result} = Character.homoglyph("test", rate: 0.5, seed: 42, charset: :cyrillic)
      assert %AttackResult{} = result
    end

    test "handles text with no substitutable characters" do
      {:ok, result} = Character.homoglyph("123", rate: 0.5)
      # Numbers might not have homoglyphs
      assert result.attacked == "123"
    end
  end

  describe "keyboard_typo/2" do
    test "injects keyboard-based typos" do
      input = "hello world"

      {:ok, result} = Character.keyboard_typo(input, rate: 0.2, seed: 42)

      assert %AttackResult{} = result
      assert result.original == "hello world"
      assert result.attack_type == :keyboard_typo
    end

    test "returns error for invalid rate" do
      assert {:error, :invalid_rate} = Character.keyboard_typo("test", rate: 1.1)
    end

    test "handles empty string" do
      {:ok, result} = Character.keyboard_typo("", rate: 0.1)
      assert result.attacked == ""
      assert result.success == false
    end

    test "uses specified keyboard layout" do
      {:ok, result} = Character.keyboard_typo("test", rate: 0.3, seed: 42, layout: :qwerty)
      assert %AttackResult{} = result
    end

    test "applies specified typo types" do
      {:ok, result} =
        Character.keyboard_typo("test", rate: 0.3, seed: 42, typo_types: [:substitution])

      assert %AttackResult{} = result
    end
  end
end
