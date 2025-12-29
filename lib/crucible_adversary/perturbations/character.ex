defmodule CrucibleAdversary.Perturbations.Character do
  @moduledoc """
  Character-level perturbation attacks for adversarial text generation.

  Implements:
  - Character swapping (typos)
  - Character deletion
  - Character insertion
  - Homoglyph substitution
  - Keyboard-based typo injection

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.swap("hello", rate: 0.2, seed: 42)
      iex> result.attack_type
      :character_swap
  """

  alias CrucibleAdversary.AttackResult

  @doc """
  Randomly swaps adjacent characters to simulate typos.

  ## Options
    * `:rate` - Float between 0.0 and 1.0, percentage of characters to swap (default: 0.1)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.swap("hello world", rate: 0.2, seed: 42)
      iex> result.original
      "hello world"
      iex> result.attack_type
      :character_swap

      iex> Character.swap("test", rate: 1.5)
      {:error, :invalid_rate}
  """
  @spec swap(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def swap(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.1)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_swap(text, rate, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :character_swap,
         success: attacked != text,
         metadata: %{rate: rate},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  # Private helper functions

  defp validate_rate(rate) when is_number(rate) and rate >= 0.0 and rate <= 1.0, do: :ok
  defp validate_rate(_), do: {:error, :invalid_rate}

  defp apply_swap(text, _rate, _seed) when byte_size(text) < 2, do: text

  defp apply_swap(text, rate, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    text
    |> String.graphemes()
    |> swap_pairs(rate)
    |> Enum.join()
  end

  defp swap_pairs(chars, _rate) when length(chars) < 2, do: chars

  defp swap_pairs(chars, rate) do
    swap_pairs(chars, rate, [])
  end

  defp swap_pairs([], _rate, acc), do: Enum.reverse(acc)

  defp swap_pairs([char], _rate, acc), do: Enum.reverse([char | acc])

  defp swap_pairs([c1, c2 | rest], rate, acc) do
    if :rand.uniform() < rate do
      # Swap these two characters
      swap_pairs(rest, rate, [c1, c2 | acc])
    else
      # Don't swap, keep original order
      swap_pairs([c2 | rest], rate, [c1 | acc])
    end
  end

  @doc """
  Deletes random characters from text.

  ## Options
    * `:rate` - Float, percentage of characters to delete (default: 0.1)
    * `:preserve_spaces` - Boolean, whether to preserve space characters (default: true)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.delete("hello world", rate: 0.2, seed: 42)
      iex> result.attack_type
      :character_delete
  """
  @spec delete(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def delete(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.1)
    preserve_spaces = Keyword.get(opts, :preserve_spaces, true)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_delete(text, rate, preserve_spaces, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :character_delete,
         success: attacked != text,
         metadata: %{rate: rate, preserve_spaces: preserve_spaces},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp apply_delete(text, _rate, _preserve_spaces, _seed) when byte_size(text) == 0, do: text

  defp apply_delete(text, rate, preserve_spaces, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    text
    |> String.graphemes()
    |> Enum.reject(fn char ->
      should_delete = :rand.uniform() < rate
      is_space = char == " "

      if preserve_spaces and is_space do
        false
      else
        should_delete
      end
    end)
    |> Enum.join()
  end

  @doc """
  Inserts random characters into text.

  ## Options
    * `:rate` - Float, percentage of insertion positions (default: 0.1)
    * `:char_pool` - List of characters to insert from (default: a-z)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.insert("test", rate: 0.2, seed: 42)
      iex> result.attack_type
      :character_insert
  """
  @spec insert(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def insert(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.1)
    char_pool = Keyword.get(opts, :char_pool, default_char_pool())
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_insert(text, rate, char_pool, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :character_insert,
         success: attacked != text,
         metadata: %{rate: rate},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp default_char_pool do
    Enum.map(?a..?z, &<<&1::utf8>>)
  end

  defp apply_insert(text, rate, char_pool, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    chars = String.graphemes(text)
    insert_indices = get_insert_indices(length(chars) + 1, rate)

    insert_at_indices(chars, insert_indices, char_pool)
    |> Enum.join()
  end

  defp get_insert_indices(max_positions, rate) do
    0..(max_positions - 1)
    |> Enum.filter(fn _pos -> :rand.uniform() < rate end)
  end

  defp insert_at_indices(chars, indices, char_pool) do
    indices_set = MapSet.new(indices)

    chars
    |> Enum.with_index()
    |> Enum.flat_map(fn {char, idx} ->
      if MapSet.member?(indices_set, idx) do
        [Enum.random(char_pool), char]
      else
        [char]
      end
    end)
    |> then(fn result ->
      # Handle insertion at the end
      if MapSet.member?(indices_set, length(chars)) do
        result ++ [Enum.random(char_pool)]
      else
        result
      end
    end)
  end

  @doc """
  Substitutes characters with visually similar Unicode characters (homoglyphs).

  ## Options
    * `:rate` - Float, percentage of characters to substitute (default: 0.1)
    * `:charset` - Atom, character set to use (:cyrillic, :greek, :all) (default: :all)
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.homoglyph("administrator", charset: :cyrillic, seed: 42)
      iex> result.attack_type
      :homoglyph
  """
  @spec homoglyph(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def homoglyph(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.1)
    charset = Keyword.get(opts, :charset, :all)
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_homoglyph(text, rate, charset, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :homoglyph,
         success: attacked != text,
         metadata: %{rate: rate, charset: charset},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp apply_homoglyph(text, _rate, _charset, _seed) when byte_size(text) == 0, do: text

  defp apply_homoglyph(text, rate, charset, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    homoglyph_mappings = get_homoglyph_map(charset)

    text
    |> String.graphemes()
    |> Enum.map_join(fn char ->
      if :rand.uniform() < rate and Map.has_key?(homoglyph_mappings, char) do
        homoglyph_mappings[char] |> Enum.random()
      else
        char
      end
    end)
  end

  defp get_homoglyph_map(:cyrillic) do
    %{
      "a" => ["а"],
      "e" => ["е"],
      "o" => ["о"],
      "p" => ["р"],
      "c" => ["с"],
      "y" => ["у"],
      "x" => ["х"],
      "A" => ["А"],
      "B" => ["В"],
      "E" => ["Е"],
      "K" => ["К"],
      "M" => ["М"],
      "H" => ["Н"],
      "O" => ["О"],
      "P" => ["Р"],
      "C" => ["С"],
      "T" => ["Т"],
      "X" => ["Х"]
    }
  end

  defp get_homoglyph_map(:greek) do
    %{
      "a" => ["α"],
      "o" => ["ο"],
      "A" => ["Α"],
      "B" => ["Β"],
      "E" => ["Ε"],
      "H" => ["Η"],
      "I" => ["Ι"],
      "K" => ["Κ"],
      "M" => ["Μ"],
      "N" => ["Ν"],
      "O" => ["Ο"],
      "P" => ["Ρ"],
      "T" => ["Τ"],
      "X" => ["Χ"],
      "Z" => ["Ζ"]
    }
  end

  defp get_homoglyph_map(:all) do
    Map.merge(get_homoglyph_map(:cyrillic), get_homoglyph_map(:greek))
  end

  @doc """
  Injects realistic typos based on keyboard layout.

  ## Options
    * `:rate` - Float, percentage of typo injection (default: 0.1)
    * `:layout` - Atom, keyboard layout (:qwerty, :dvorak) (default: :qwerty)
    * `:typo_types` - List of atoms, types to include [:substitution, :insertion, :deletion, :transposition] (default: [:substitution])
    * `:seed` - Integer, random seed for reproducibility (default: nil)

  ## Returns
    * `{:ok, %AttackResult{}}` - Success with attack result
    * `{:error, reason}` - Error with reason

  ## Examples

      iex> alias CrucibleAdversary.Perturbations.Character
      iex> {:ok, result} = Character.keyboard_typo("hello", layout: :qwerty, seed: 42)
      iex> result.attack_type
      :keyboard_typo
  """
  @spec keyboard_typo(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  def keyboard_typo(text, opts \\ []) do
    rate = Keyword.get(opts, :rate, 0.1)
    layout = Keyword.get(opts, :layout, :qwerty)
    typo_types = Keyword.get(opts, :typo_types, [:substitution])
    seed = Keyword.get(opts, :seed)

    with :ok <- validate_rate(rate) do
      attacked = apply_keyboard_typo(text, rate, layout, typo_types, seed)

      {:ok,
       %AttackResult{
         original: text,
         attacked: attacked,
         attack_type: :keyboard_typo,
         success: attacked != text,
         metadata: %{rate: rate, layout: layout, typo_types: typo_types},
         timestamp: DateTime.utc_now()
       }}
    end
  end

  defp apply_keyboard_typo(text, _rate, _layout, _typo_types, _seed) when byte_size(text) == 0,
    do: text

  defp apply_keyboard_typo(text, rate, layout, typo_types, seed) do
    if seed, do: :rand.seed(:exsss, {seed, seed, seed})

    adjacency = get_keyboard_adjacency(layout)

    text
    |> String.graphemes()
    |> Enum.map_join(fn char ->
      if :rand.uniform() < rate and Map.has_key?(adjacency, char) do
        typo_type = Enum.random(typo_types)
        apply_typo(char, typo_type, adjacency)
      else
        char
      end
    end)
  end

  defp apply_typo(char, :substitution, adjacency) do
    case Map.get(adjacency, char) do
      [] -> char
      adjacent_keys -> Enum.random(adjacent_keys)
    end
  end

  defp apply_typo(char, _other_type, _adjacency) do
    # For now, only substitution is implemented
    char
  end

  defp get_keyboard_adjacency(:qwerty) do
    %{
      "a" => ["q", "w", "s", "z"],
      "b" => ["v", "g", "h", "n"],
      "c" => ["x", "d", "f", "v"],
      "d" => ["s", "e", "r", "f", "c", "x"],
      "e" => ["w", "r", "d", "s"],
      "f" => ["d", "r", "t", "g", "v", "c"],
      "g" => ["f", "t", "y", "h", "b", "v"],
      "h" => ["g", "y", "u", "j", "n", "b"],
      "i" => ["u", "o", "k", "j"],
      "j" => ["h", "u", "i", "k", "m", "n"],
      "k" => ["j", "i", "o", "l", "m"],
      "l" => ["k", "o", "p"],
      "m" => ["n", "j", "k"],
      "n" => ["b", "h", "j", "m"],
      "o" => ["i", "p", "l", "k"],
      "p" => ["o", "l"],
      "q" => ["w", "a"],
      "r" => ["e", "t", "f", "d"],
      "s" => ["a", "w", "e", "d", "x", "z"],
      "t" => ["r", "y", "g", "f"],
      "u" => ["y", "i", "j", "h"],
      "v" => ["c", "f", "g", "b"],
      "w" => ["q", "e", "s", "a"],
      "x" => ["z", "s", "d", "c"],
      "y" => ["t", "u", "h", "g"],
      "z" => ["a", "s", "x"]
    }
  end

  defp get_keyboard_adjacency(:dvorak) do
    # Simplified Dvorak layout
    %{
      "a" => ["o", "e"],
      "e" => ["a", "o", "u"],
      "i" => ["c", "d"],
      "o" => ["a", "e"],
      "u" => ["e", "i"]
    }
  end
end
