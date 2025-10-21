defmodule CrucibleAdversary.Metrics.ASR do
  @moduledoc """
  Attack Success Rate (ASR) metrics.

  Measures the effectiveness of adversarial attacks.

  ## Examples

      iex> alias CrucibleAdversary.{AttackResult, Metrics.ASR}
      iex> results = [%AttackResult{success: true, attack_type: :character_swap, original: "a", attacked: "b"}]
      iex> success_fn = fn r -> r.success end
      iex> metrics = ASR.calculate(results, success_fn)
      iex> metrics.overall_asr
      1.0
  """

  alias CrucibleAdversary.AttackResult

  @doc """
  Calculates attack success rate.

  ## Parameters
    * `attack_results` - List of AttackResult structs
    * `success_fn` - Function that determines if attack succeeded

  ## Returns
    Map containing:
    * `:overall_asr` - Overall success rate
    * `:by_attack_type` - Success rate by attack type
    * `:total_attacks` - Total number of attacks
    * `:successful_attacks` - Number of successful attacks

  ## Examples

      iex> alias CrucibleAdversary.{AttackResult, Metrics.ASR}
      iex> results = [
      ...>   %AttackResult{attack_type: :character_swap, success: true, original: "a", attacked: "b"},
      ...>   %AttackResult{attack_type: :character_swap, success: false, original: "c", attacked: "c"}
      ...> ]
      iex> success_fn = fn result -> result.success end
      iex> metrics = ASR.calculate(results, success_fn)
      iex> metrics.overall_asr
      0.5
  """
  @spec calculate(list(AttackResult.t()), function()) :: map()
  def calculate([], _success_fn) do
    %{
      overall_asr: 0.0,
      by_attack_type: %{},
      total_attacks: 0,
      successful_attacks: 0
    }
  end

  def calculate(attack_results, success_fn) do
    total = length(attack_results)
    successful = Enum.count(attack_results, success_fn)

    overall_asr = calculate_rate(successful, total)

    by_type =
      attack_results
      |> group_by_type()
      |> Enum.map(fn {type, results} ->
        type_successful = Enum.count(results, success_fn)
        type_total = length(results)
        {type, calculate_rate(type_successful, type_total)}
      end)
      |> Enum.into(%{})

    %{
      overall_asr: overall_asr,
      by_attack_type: by_type,
      total_attacks: total,
      successful_attacks: successful
    }
  end

  @doc """
  Calculates query efficiency (success per query).

  ## Parameters
    * `attack_results` - List of attack results with query counts
    * `total_queries` - Total number of queries made

  ## Returns
    Map with efficiency metrics
  """
  @spec query_efficiency(list(map()), non_neg_integer()) :: map()
  def query_efficiency([], 0) do
    %{
      total_queries: 0,
      successful_attacks: 0,
      efficiency: 0.0,
      avg_queries_per_success: 0.0
    }
  end

  def query_efficiency(attack_results, total_queries) do
    successful_attacks = Enum.count(attack_results, fn r -> r.success end)

    efficiency =
      if total_queries > 0 do
        successful_attacks / total_queries
      else
        0.0
      end

    total_successful_queries =
      attack_results
      |> Enum.filter(fn r -> r.success end)
      |> Enum.map(fn r -> Map.get(r, :queries, 1) end)
      |> Enum.sum()

    avg_queries_per_success =
      if successful_attacks > 0 do
        total_successful_queries / successful_attacks
      else
        0.0
      end

    %{
      total_queries: total_queries,
      successful_attacks: successful_attacks,
      efficiency: efficiency,
      avg_queries_per_success: avg_queries_per_success
    }
  end

  # Private helpers

  defp group_by_type(results) do
    Enum.group_by(results, fn result -> result.attack_type end)
  end

  defp calculate_rate(successful, total) when total > 0 do
    successful / total
  end

  defp calculate_rate(_successful, 0), do: 0.0
end
