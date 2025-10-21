defmodule CrucibleAdversary.Perturbations.Word do
  @moduledoc """
  Word-level perturbation attacks.

  Implements:
  - Word deletion
  - Word insertion
  - Synonym replacement
  - Word order shuffling

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Word
      iex> {:ok, result} = Word.delete("hello world", rate: 0.5, seed: 42)
      iex> result.attack_type
      :word_deletion
  """

  alias CrucibleAdversary.AttackResult

  @doc """
  Randomly deletes words from text.

  ## Options
    * `:rate` - Float, percentage of words to delete (default: 0.2)
    * `:strategy` - Atom, deletion strategy (:random, :importance_based) (default: :random)
    * `:preserve_stopwords` - Boolean (default: false)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason
  """
  @spec delete(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def delete(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.2)
    preserve_stopwords = Keyword.get(opts, :preserve_stopwords, false)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_delete(text, rate, preserve_stopwords, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :word_deletion,
         success: attacked != text,
         metadata: %{rate: rate, preserve_stopwords: preserve_stopwords},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp validate_rate(rate) when is_number(rate) and rate >= 0.0 and rate <= 1.0, do: :ok
  defp validate_rate(_), do: {:error, :invalid_rate}

  defp apply_delete("", _rate, _preserve_stopwords, _seed), do: ""

  defp apply_delete(text, rate, preserve_stopwords, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    text
    |> tokenize()
    |> Enum.reject(fn word ->
      should_delete = :rand.uniform() < rate
      is_stopword = is_stopword?(word)

      if preserve_stopwords and is_stopword do
        false
      else
        should_delete
      end
    end)
    |> Enum.join(" ")
  end

  @doc """
  Inserts random words into text.

  ## Options
    * `:rate` - Float, percentage of insertion positions (default: 0.2)
    * `:noise_type` - Atom, type of noise (:random_words, :adversarial) (default: :random_words)
    * `:dictionary` - List of words to insert from (default: common English words)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason
  """
  @spec insert(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def insert(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.2)
    dictionary = Keyword.get(opts, :dictionary, default_dictionary())
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_insert(text, rate, dictionary, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :word_insertion,
         success: attacked != text,
         metadata: %{rate: rate},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp default_dictionary do
    ["the", "and", "or", "but", "very", "really", "quite", "maybe", "perhaps", "however"]
  end

  defp apply_insert(text, rate, dictionary, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    words = if text == "", do: [], else: tokenize(text)
    insert_indices = get_insert_indices(length(words) + 1, rate)

    insert_words_at_indices(words, insert_indices, dictionary)
    |> Enum.join(" ")
  end

  defp get_insert_indices(max_positions, rate) do
    0..(max_positions - 1)
    |> Enum.filter(fn _pos -> :rand.uniform() < rate end)
  end

  defp insert_words_at_indices(words, indices, dictionary) do
    indices_set = MapSet.new(indices)

    words
    |> Enum.with_index()
    |> Enum.flat_map(fn {word, idx} ->
      if MapSet.member?(indices_set, idx) do
        [Enum.random(dictionary), word]
      else
        [word]
      end
    end)
    |> then(fn result ->
      if MapSet.member?(indices_set, length(words)) do
        result ++ [Enum.random(dictionary)]
      else
        result
      end
    end)
  end

  @doc """
  Replaces words with synonyms while preserving semantic meaning.

  ## Options
    * `:rate` - Float, percentage of words to replace (default: 0.3)
    * `:dictionary` - Atom, dictionary source (:simple, :wordnet) (default: :simple)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Word
      iex> {:ok, result} = Word.synonym_replace("The quick brown fox", rate: 0.5, seed: 42)
      iex> result.attack_type
      :synonym_replacement
  """
  @spec synonym_replace(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def synonym_replace(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.3)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_synonym_replace(text, rate, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :synonym_replacement,
         success: attacked != text,
         metadata: %{rate: rate},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp apply_synonym_replace("", _rate, _seed), do: ""

  defp apply_synonym_replace(text, rate, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    synonym_map = get_synonym_map()

    text
    |> tokenize()
    |> Enum.map(fn word ->
      lower_word = String.downcase(word)

      if :rand.uniform() < rate and Map.has_key?(synonym_map, lower_word) do
        synonym_map[lower_word] |> Enum.random()
      else
        word
      end
    end)
    |> Enum.join(" ")
  end

  defp get_synonym_map do
    %{
      "quick" => ["fast", "rapid", "swift", "speedy"],
      "fast" => ["quick", "rapid", "swift"],
      "dangerous" => ["hazardous", "risky", "unsafe", "perilous"],
      "happy" => ["joyful", "cheerful", "glad", "pleased"],
      "sad" => ["unhappy", "sorrowful", "miserable", "dejected"],
      "big" => ["large", "huge", "enormous", "massive"],
      "small" => ["tiny", "little", "minute", "minuscule"],
      "good" => ["excellent", "great", "fine", "wonderful"],
      "bad" => ["poor", "terrible", "awful", "dreadful"],
      "beautiful" => ["pretty", "lovely", "attractive", "gorgeous"],
      "ugly" => ["unattractive", "hideous", "unsightly"],
      "smart" => ["intelligent", "clever", "bright", "brilliant"],
      "stupid" => ["dumb", "foolish", "idiotic", "moronic"],
      "easy" => ["simple", "effortless", "straightforward"],
      "hard" => ["difficult", "challenging", "tough"],
      "old" => ["ancient", "aged", "elderly"],
      "new" => ["fresh", "recent", "modern"],
      "hot" => ["warm", "heated", "burning"],
      "cold" => ["cool", "chilly", "freezing"],
      "strong" => ["powerful", "mighty", "robust"],
      "weak" => ["feeble", "frail", "fragile"]
    }
  end

  @doc """
  Shuffles word order while attempting to maintain some coherence.

  ## Options
    * `:shuffle_type` - Atom, shuffle strategy (:random, :adjacent_only) (default: :adjacent_only)
    * `:rate` - Float, percentage of words to shuffle (default: 0.2)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason
  """
  @spec shuffle(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def shuffle(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.2)
    shuffle_type = Keyword.get(opts, :shuffle_type, :adjacent_only)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_shuffle(text, rate, shuffle_type, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :word_shuffle,
         success: attacked != text,
         metadata: %{rate: rate, shuffle_type: shuffle_type},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp apply_shuffle("", _rate, _shuffle_type, _seed), do: ""

  defp apply_shuffle(text, rate, shuffle_type, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    words = tokenize(text)

    case shuffle_type do
      :adjacent_only -> shuffle_adjacent(words, rate)
      :random -> shuffle_random(words, rate)
    end
    |> Enum.join(" ")
  end

  defp shuffle_adjacent(words, _rate) when length(words) < 2, do: words

  defp shuffle_adjacent(words, rate) do
    shuffle_adjacent(words, rate, [])
  end

  defp shuffle_adjacent([], _rate, acc), do: Enum.reverse(acc)
  defp shuffle_adjacent([word], _rate, acc), do: Enum.reverse([word | acc])

  defp shuffle_adjacent([w1, w2 | rest], rate, acc) do
    if :rand.uniform() < rate do
      # Swap these two words
      shuffle_adjacent(rest, rate, [w1, w2 | acc])
    else
      # Keep original order
      shuffle_adjacent([w2 | rest], rate, [w1 | acc])
    end
  end

  defp shuffle_random(words, rate) do
    words
    |> Enum.map(fn word ->
      {word, if(:rand.uniform() < rate, do: :rand.uniform(), else: 1.0)}
    end)
    |> Enum.sort_by(fn {_word, priority} -> priority end)
    |> Enum.map(fn {word, _priority} -> word end)
  end

  # Helper functions

  defp tokenize(text) do
    text
    |> String.split(~r/\s+/, trim: true)
  end

  @stopwords ~w(the a an and or but in on at to for of with)

  defp is_stopword?(word) do
    String.downcase(word) in @stopwords
  end
end
