defmodule CrucibleAdversary.Attacks.ExtractionTest do
  use ExUnit.Case, async: true

  alias CrucibleAdversary.Attacks.Extraction
  alias CrucibleAdversary.AttackResult

  doctest Extraction

  describe "repetition_attack/2" do
    test "generates repetition attack with default options" do
      {:ok, result} = Extraction.repetition_attack("Test prompt")

      assert %AttackResult{} = result
      assert result.original == "Test prompt"
      assert result.attack_type == :data_extraction_repetition
      assert result.success == true
      assert String.contains?(result.attacked, "Test prompt")
      assert String.length(result.attacked) > String.length("Test prompt")
    end

    test "respects target_length option" do
      {:ok, result} = Extraction.repetition_attack("Short", target_length: 500)

      assert String.length(result.attacked) >= 500
      assert result.metadata.target_length == 500
      assert result.metadata.actual_length >= 500
    end

    test "includes repetition count in metadata" do
      {:ok, result} = Extraction.repetition_attack("Test", repetition_count: 10)

      assert result.metadata.repetition_count == 10
      # Count occurrences of "Test" in attacked string
      count = result.attacked |> String.split("Test") |> length() |> Kernel.-(1)
      assert count >= 10
    end

    test "supports different repetition strategies" do
      {:ok, result1} = Extraction.repetition_attack("Text", strategy: :simple)
      {:ok, result2} = Extraction.repetition_attack("Text", strategy: :incremental)
      {:ok, result3} = Extraction.repetition_attack("Text", strategy: :pattern)

      assert result1.metadata.strategy == :simple
      assert result2.metadata.strategy == :incremental
      assert result3.metadata.strategy == :pattern

      # All should produce different outputs
      assert result1.attacked != result2.attacked
      assert result2.attacked != result3.attacked
    end

    test "handles empty input" do
      {:ok, result} = Extraction.repetition_attack("")

      assert result.original == ""
      assert result.attacked != ""
      assert result.success == true
    end

    test "includes extraction indicators" do
      {:ok, result} = Extraction.repetition_attack("Sensitive")

      assert is_list(result.metadata.extraction_indicators)
      assert :repetition in result.metadata.extraction_indicators
    end
  end

  describe "memorization_probe/2" do
    test "generates memorization probe attack" do
      {:ok, result} = Extraction.memorization_probe("Complete this: The quick brown")

      assert %AttackResult{} = result
      assert result.attack_type == :data_extraction_memorization
      assert result.success == true
      assert String.contains?(result.attacked, "Complete this:")
    end

    test "includes continuation prompts" do
      {:ok, result} = Extraction.memorization_probe("Start text", probe_type: :continuation)

      assert result.metadata.probe_type == :continuation
      assert String.contains?(result.attacked, "continue")
    end

    test "supports pattern probe type" do
      {:ok, result} = Extraction.memorization_probe("Pattern", probe_type: :pattern_completion)

      assert result.metadata.probe_type == :pattern_completion
      assert String.length(result.attacked) > String.length("Pattern")
    end

    test "includes common memorization triggers" do
      {:ok, result} = Extraction.memorization_probe("Text", use_triggers: true)

      triggers = result.metadata.triggers_used || []
      assert is_list(triggers)
      assert Enum.any?(triggers, &is_binary/1)
    end

    test "generates multiple probe variants" do
      {:ok, result} = Extraction.memorization_probe("Base", variants: 3)

      assert result.metadata.variants_generated == 3
      assert is_list(result.metadata.variant_attacks)
      assert length(result.metadata.variant_attacks) == 3
    end
  end

  describe "pii_extraction/2" do
    test "generates PII extraction attack" do
      {:ok, result} = Extraction.pii_extraction("User data query")

      assert %AttackResult{} = result
      assert result.attack_type == :data_extraction_pii
      assert result.success == true
    end

    test "targets specific PII types" do
      {:ok, result} =
        Extraction.pii_extraction(
          "Extract info",
          pii_types: [:email, :phone, :ssn]
        )

      assert result.metadata.pii_types == [:email, :phone, :ssn]
      assert String.length(result.attacked) > String.length("Extract info")
    end

    test "includes context manipulation" do
      {:ok, result} = Extraction.pii_extraction("Query", context_manipulation: true)

      assert result.metadata.context_manipulation == true
      # Should contain context-switching phrases
      lower_attacked = String.downcase(result.attacked)

      assert String.contains?(lower_attacked, "provide") or
               String.contains?(lower_attacked, "show") or
               String.contains?(lower_attacked, "list")
    end

    test "supports different extraction strategies" do
      {:ok, result1} = Extraction.pii_extraction("Test", strategy: :direct)
      {:ok, result2} = Extraction.pii_extraction("Test", strategy: :indirect)
      {:ok, result3} = Extraction.pii_extraction("Test", strategy: :contextual)

      assert result1.metadata.strategy == :direct
      assert result2.metadata.strategy == :indirect
      assert result3.metadata.strategy == :contextual
    end

    test "includes social engineering indicators" do
      {:ok, result} = Extraction.pii_extraction("Extract", use_social_engineering: true)

      assert result.metadata.social_engineering == true
      assert is_list(result.metadata.techniques_used)
    end
  end

  describe "context_confusion/2" do
    test "generates context confusion attack" do
      {:ok, result} = Extraction.context_confusion("Original prompt")

      assert %AttackResult{} = result
      assert result.attack_type == :data_extraction_context_confusion
      assert result.success == true
    end

    test "creates multiple context switches" do
      {:ok, result} = Extraction.context_confusion("Prompt", switches: 3)

      assert result.metadata.context_switches == 3
      # Should have multiple delimiter-like patterns
      assert result.attacked =~ ~r/\n.*\n/
    end

    test "confuses instruction boundaries" do
      {:ok, result} =
        Extraction.context_confusion(
          "Task A",
          confusion_type: :boundary
        )

      assert result.metadata.confusion_type == :boundary
      assert String.contains?(result.attacked, "Task A")
    end
  end

  describe "integration" do
    test "all extraction attacks return valid AttackResult" do
      attacks = [
        &Extraction.repetition_attack/2,
        &Extraction.memorization_probe/2,
        &Extraction.pii_extraction/2,
        &Extraction.context_confusion/2
      ]

      for attack_fn <- attacks do
        {:ok, result} = attack_fn.("Test input", [])
        assert %AttackResult{} = result
        assert result.success == true
        assert is_binary(result.original)
        assert is_binary(result.attacked)
        assert is_atom(result.attack_type)
        assert %DateTime{} = result.timestamp
        assert is_map(result.metadata)
      end
    end

    test "extraction attacks produce different outputs" do
      input = "Test input for extraction"

      {:ok, r1} = Extraction.repetition_attack(input)
      {:ok, r2} = Extraction.memorization_probe(input)
      {:ok, r3} = Extraction.pii_extraction(input)
      {:ok, r4} = Extraction.context_confusion(input)

      # All should have different attack types
      types = [r1.attack_type, r2.attack_type, r3.attack_type, r4.attack_type]
      assert length(Enum.uniq(types)) == 4

      # All should modify the input differently
      outputs = [r1.attacked, r2.attacked, r3.attacked, r4.attacked]
      assert length(Enum.uniq(outputs)) == 4
    end
  end
end
