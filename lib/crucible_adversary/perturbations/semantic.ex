defmodule CrucibleAdversary.Perturbations.Semantic do
  @moduledoc """
  Semantic-level perturbation attacks.

  Implements higher-level semantic transformations that preserve meaning
  while changing surface form:
  - Paraphrasing
  - Back-translation simulation
  - Sentence reordering
  - Formality changes

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Semantic
      iex> {:ok, result} = Semantic.paraphrase("The quick brown fox", seed: 42)
      iex> result.attack_type
      :semantic_paraphrase
  """

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Perturbations.Word

  @doc """
  Paraphrases text while preserving semantic meaning.

  Uses synonym replacement and minor structural changes to simulate paraphrasing.

  ## Options
    * `:strategy` - Paraphrase strategy (:simple, :complex) (default: :simple)
    * `:seed` - Random seed for reproducibility (default: nil)

  ## Returns
    {:ok, %AttackResult{}} or {:error, reason}

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Semantic
      iex> {:ok, result} = Semantic.paraphrase("The cat sat", seed: 42)
      iex> result.attack_type
      :semantic_paraphrase
  """
  @spec paraphrase(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def paraphrase(text, opts \\ [])

  def paraphrase("", _opts) do
    {:ok,
     %AttackResult{
       original: "",
       attacked: "",
       attack_type: :semantic_paraphrase,
       success: false,
       metadata: %{},
       timestamp: DateTime.utc_now()
     }}
  end

  def paraphrase(text, opts) do
    strategy = Keyword.get(opts, :strategy, :simple)
    seed = Keyword.get(opts, :seed)

    # Use synonym replacement as base paraphrasing technique
    {:ok, synonym_result} = Word.synonym_replace(text, rate: 0.4, seed: seed)

    attacked =
      case strategy do
        :simple -> synonym_result.attacked
        :complex -> apply_structural_changes(synonym_result.attacked, seed)
      end

    {:ok,
     %AttackResult{
       original: text,
       attacked: attacked,
       attack_type: :semantic_paraphrase,
       success: attacked != text,
       metadata: %{strategy: strategy},
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Simulates back-translation artifacts.

  Applies transformations that mimic errors from translating to another language
  and back, such as article changes, word order variations, etc.

  ## Options
    * `:intermediate` - Intermediate language (:spanish, :french, :german) (default: :spanish)
    * `:seed` - Random seed for reproducibility (default: nil)

  ## Returns
    {:ok, %AttackResult{}} or {:error, reason}

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Semantic
      iex> {:ok, result} = Semantic.back_translate("The cat", intermediate: :spanish)
      iex> result.attack_type
      :semantic_back_translate
  """
  @spec back_translate(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def back_translate(text, opts \\ [])

  def back_translate("", _opts) do
    {:ok,
     %AttackResult{
       original: "",
       attacked: "",
       attack_type: :semantic_back_translate,
       success: false,
       metadata: %{},
       timestamp: DateTime.utc_now()
     }}
  end

  def back_translate(text, opts) do
    intermediate = Keyword.get(opts, :intermediate, :spanish)
    seed = Keyword.get(opts, :seed)

    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    # Simulate translation artifacts
    attacked =
      text
      |> simulate_translation_artifacts(intermediate)
      |> maybe_reorder_adjectives(seed)

    {:ok,
     %AttackResult{
       original: text,
       attacked: attacked,
       attack_type: :semantic_back_translate,
       success: attacked != text,
       metadata: %{intermediate: intermediate},
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Reorders sentences in multi-sentence text.

  ## Options
    * `:seed` - Random seed for reproducibility (default: nil)

  ## Returns
    {:ok, %AttackResult{}} or {:error, reason}

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Semantic
      iex> {:ok, result} = Semantic.sentence_reorder("A. B. C.", seed: 42)
      iex> result.attack_type
      :semantic_sentence_reorder
  """
  @spec sentence_reorder(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def sentence_reorder(text, opts \\ [])

  def sentence_reorder("", _opts) do
    {:ok,
     %AttackResult{
       original: "",
       attacked: "",
       attack_type: :semantic_sentence_reorder,
       success: false,
       metadata: %{},
       timestamp: DateTime.utc_now()
     }}
  end

  def sentence_reorder(text, opts) do
    seed = Keyword.get(opts, :seed)

    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    sentences = split_sentences(text)

    attacked =
      if length(sentences) > 1 do
        sentences
        |> Enum.shuffle()
        |> Enum.join(" ")
      else
        text
      end

    {:ok,
     %AttackResult{
       original: text,
       attacked: attacked,
       attack_type: :semantic_sentence_reorder,
       success: attacked != text,
       metadata: %{sentence_count: length(sentences)},
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Changes text formality level.

  ## Options
    * `:direction` - Formality direction (:formal, :informal) (default: :informal)
    * `:seed` - Random seed for reproducibility (default: nil)

  ## Returns
    {:ok, %AttackResult{}} or {:error, reason}

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Semantic
      iex> {:ok, result} = Semantic.formality_change("Hello sir", direction: :informal)
      iex> result.attack_type
      :semantic_formality_change
  """
  @spec formality_change(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def formality_change(text, opts \\ [])

  def formality_change("", _opts) do
    {:ok,
     %AttackResult{
       original: "",
       attacked: "",
       attack_type: :semantic_formality_change,
       success: false,
       metadata: %{},
       timestamp: DateTime.utc_now()
     }}
  end

  def formality_change(text, opts) do
    direction = Keyword.get(opts, :direction, :informal)
    seed = Keyword.get(opts, :seed)

    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    attacked =
      case direction do
        :informal -> apply_informal_transformations(text)
        :formal -> apply_formal_transformations(text)
      end

    {:ok,
     %AttackResult{
       original: text,
       attacked: attacked,
       attack_type: :semantic_formality_change,
       success: attacked != text,
       metadata: %{direction: direction},
       timestamp: DateTime.utc_now()
     }}
  end

  # Private helpers

  defp apply_structural_changes(text, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    # Simple structural variation: sometimes swap adjacent words
    words = String.split(text)

    if length(words) > 2 and :rand.uniform() > 0.5 do
      # Swap first two words if it makes sense
      [w1, w2 | rest] = words
      Enum.join([w2, w1 | rest], " ")
    else
      text
    end
  end

  defp simulate_translation_artifacts(text, intermediate) do
    # Simulate common translation artifacts based on language
    case intermediate do
      :spanish ->
        # Spanish tends to drop articles sometimes and add "the" before nouns differently
        text
        |> String.replace(~r/\bthe\s+/i, fn _match ->
          if :rand.uniform() > 0.5, do: "", else: "the "
        end)
        |> String.replace(~r/\ba\s+/i, fn _match ->
          if :rand.uniform() > 0.6, do: "the ", else: "a "
        end)

      :french ->
        # French might reorder adjectives and use different articles
        text
        |> String.replace("the", "a")

      :german ->
        # German might have different word order
        text
        |> String.replace("on the", "on")

      _ ->
        text
    end
  end

  defp maybe_reorder_adjectives(text, _seed) do
    # Simple simulation: no actual reordering for now
    text
  end

  defp split_sentences(text) do
    text
    |> String.split(~r/[.!?]+\s+/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn sentence ->
      # Add back period if missing
      if String.ends_with?(sentence, [".", "!", "?"]) do
        sentence
      else
        sentence <> "."
      end
    end)
  end

  @informal_replacements %{
    "Hello" => "Hi",
    "hello" => "hi",
    "How are you" => "How's it going",
    "how are you" => "how's it going",
    "Thank you" => "Thanks",
    "thank you" => "thanks",
    "Please" => "Pls",
    "please" => "pls",
    "you are" => "you're",
    "I am" => "I'm",
    "cannot" => "can't",
    "do not" => "don't"
  }

  @formal_replacements %{
    "Hi" => "Hello",
    "hi" => "hello",
    "hey" => "hello",
    "Hey" => "Hello",
    "Thanks" => "Thank you",
    "thanks" => "thank you",
    "pls" => "please",
    "Pls" => "Please",
    "you're" => "you are",
    "I'm" => "I am",
    "can't" => "cannot",
    "don't" => "do not",
    "whats" => "what is",
    "hows" => "how is"
  }

  defp apply_informal_transformations(text) do
    Enum.reduce(@informal_replacements, text, fn {formal, informal}, acc ->
      String.replace(acc, formal, informal)
    end)
  end

  defp apply_formal_transformations(text) do
    Enum.reduce(@formal_replacements, text, fn {informal, formal}, acc ->
      String.replace(acc, informal, formal)
    end)
  end
end
