defmodule CrucibleAdversary.Metrics.Consistency do
  @moduledoc """
  Consistency and semantic similarity metrics.

  Measures how similar outputs are between original and perturbed inputs.

  ## Examples

      iex> alias CrucibleAdversary.Metrics.Consistency
      iex> Consistency.semantic_similarity("hello", "hello", method: :jaccard)
      1.0
  """

  @doc """
  Calculates semantic similarity between two texts.

  ## Options
    * `:method` - Atom, similarity method (:jaccard, :cosine, :edit_distance) (default: :jaccard)

  ## Returns
    Float between 0.0 (completely different) and 1.0 (identical)

  ## Examples

      iex> alias CrucibleAdversary.Metrics.Consistency
      iex> Consistency.semantic_similarity("the cat sat", "the cat sat", method: :jaccard)
      1.0
  """
  @spec semantic_similarity(String.t(), String.t(), keyword()) :: float()
  def semantic_similarity(text1, text2, opts \\ []) do
    method = Keyword.get(opts, :method, :jaccard)

    case method do
      :jaccard -> jaccard_similarity(text1, text2)
      :edit_distance -> edit_distance_similarity(text1, text2)
      # Simplified: use jaccard for now
      :cosine -> jaccard_similarity(text1, text2)
    end
  end

  @doc """
  Calculates output consistency across original and perturbed inputs.

  ## Parameters
    * `original_outputs` - List of original model outputs
    * `perturbed_outputs` - List of perturbed model outputs
    * `opts` - Options including :method

  ## Returns
    Map containing:
    * `:mean_consistency` - Average consistency score
    * `:median_consistency` - Median consistency score
    * `:std_consistency` - Standard deviation
    * `:min` - Minimum consistency
    * `:max` - Maximum consistency
  """
  @spec consistency(list(String.t()), list(String.t()), keyword()) :: map()
  def consistency(original_outputs, perturbed_outputs, opts \\ [])

  def consistency([], [], _opts) do
    %{
      mean_consistency: 0.0,
      median_consistency: 0.0,
      std_consistency: 0.0,
      min: 0.0,
      max: 0.0
    }
  end

  def consistency(original_outputs, perturbed_outputs, opts) do
    similarities =
      Enum.zip(original_outputs, perturbed_outputs)
      |> Enum.map(fn {orig, pert} ->
        semantic_similarity(orig, pert, opts)
      end)

    calculate_stats(similarities)
  end

  # Private helpers

  defp jaccard_similarity("", ""), do: 1.0

  defp jaccard_similarity(text1, text2) do
    words1 = text1 |> String.downcase() |> String.split() |> MapSet.new()
    words2 = text2 |> String.downcase() |> String.split() |> MapSet.new()

    intersection = MapSet.intersection(words1, words2) |> MapSet.size()
    union = MapSet.union(words1, words2) |> MapSet.size()

    if union == 0 do
      1.0
    else
      intersection / union
    end
  end

  defp edit_distance_similarity(text1, text2) do
    distance = levenshtein_distance(text1, text2)
    max_len = max(String.length(text1), String.length(text2))

    if max_len == 0 do
      1.0
    else
      1.0 - distance / max_len
    end
  end

  defp levenshtein_distance("", text2), do: String.length(text2)
  defp levenshtein_distance(text1, ""), do: String.length(text1)

  defp levenshtein_distance(text1, text2) do
    s1 = String.graphemes(text1)
    s2 = String.graphemes(text2)
    _len1 = length(s1)
    len2 = length(s2)

    # Initialize the matrix
    initial_row = Enum.to_list(0..len2)

    # Calculate distances row by row
    {final_row, _} =
      Enum.reduce(Enum.with_index(s1, 1), {initial_row, 1}, fn {char1, i}, {prev_row, _row_idx} ->
        new_row =
          Enum.reduce(Enum.with_index(s2, 1), [i], fn {char2, j}, acc ->
            cost_above = Enum.at(prev_row, j)
            cost_left = hd(acc)
            cost_diagonal = Enum.at(prev_row, j - 1)

            cost =
              if char1 == char2 do
                cost_diagonal
              else
                1 + min(cost_left, min(cost_above, cost_diagonal))
              end

            [cost | acc]
          end)
          |> Enum.reverse()

        {new_row, i + 1}
      end)

    List.last(final_row)
  end

  defp calculate_stats([]) do
    %{
      mean_consistency: 0.0,
      median_consistency: 0.0,
      std_consistency: 0.0,
      min: 0.0,
      max: 0.0
    }
  end

  defp calculate_stats(similarities) do
    sorted = Enum.sort(similarities)
    count = length(similarities)

    mean = Enum.sum(similarities) / count
    min_val = List.first(sorted)
    max_val = List.last(sorted)

    median =
      if rem(count, 2) == 0 do
        (Enum.at(sorted, div(count, 2) - 1) + Enum.at(sorted, div(count, 2))) / 2
      else
        Enum.at(sorted, div(count, 2))
      end

    variance =
      similarities
      |> Enum.map(fn x -> :math.pow(x - mean, 2) end)
      |> Enum.sum()
      |> Kernel./(count)

    std = :math.sqrt(variance)

    %{
      mean_consistency: mean,
      median_consistency: median,
      std_consistency: std,
      min: min_val,
      max: max_val
    }
  end
end
