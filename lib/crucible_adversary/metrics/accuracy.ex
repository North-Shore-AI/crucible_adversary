defmodule CrucibleAdversary.Metrics.Accuracy do
  @moduledoc """
  Accuracy-based robustness metrics.

  Calculates:
  - Accuracy drop under adversarial attacks
  - Robust accuracy
  - Relative accuracy degradation

  ## Examples

      iex> original = [{:pred, :label, true}, {:pred, :label, true}]
      iex> attacked = [{:pred, :label, true}, {:pred, :label, false}]
      iex> result = CrucibleAdversary.Metrics.Accuracy.drop(original, attacked)
      iex> result.original_accuracy
      1.0
      iex> result.attacked_accuracy
      0.5
  """

  @doc """
  Calculates accuracy drop between clean and adversarial results.

  ## Parameters
    * `original_results` - List of tuples {prediction, label, correct?}
    * `attacked_results` - List of tuples {prediction, label, correct?}

  ## Returns
    Map containing:
    * `:original_accuracy` - Accuracy on clean inputs
    * `:attacked_accuracy` - Accuracy on adversarial inputs
    * `:absolute_drop` - Absolute difference
    * `:relative_drop` - Relative percentage drop
    * `:severity` - Atom (:low, :moderate, :high, :critical)

  ## Examples

      iex> original = [{:pred, :label, true}, {:pred, :label, true}]
      iex> attacked = [{:pred, :label, true}, {:pred, :label, false}]
      iex> result = CrucibleAdversary.Metrics.Accuracy.drop(original, attacked)
      iex> result.absolute_drop
      0.5
  """
  @spec drop(list(tuple()), list(tuple())) :: map()
  def drop(original_results, attacked_results) do
    original_accuracy = calculate_accuracy(original_results)
    attacked_accuracy = calculate_accuracy(attacked_results)

    absolute_drop = original_accuracy - attacked_accuracy

    relative_drop =
      if original_accuracy > 0 do
        absolute_drop / original_accuracy
      else
        0.0
      end

    severity = determine_severity(relative_drop)

    %{
      original_accuracy: original_accuracy,
      attacked_accuracy: attacked_accuracy,
      absolute_drop: absolute_drop,
      relative_drop: relative_drop,
      severity: severity
    }
  end

  @doc """
  Calculates robust accuracy (accuracy on adversarial examples only).

  ## Parameters
    * `predictions` - List of predicted values
    * `ground_truth` - List of true labels

  ## Returns
    Float between 0.0 and 1.0

  ## Examples

      iex> predictions = [:cat, :dog, :bird]
      iex> ground_truth = [:cat, :dog, :cat]
      iex> CrucibleAdversary.Metrics.Accuracy.robust_accuracy(predictions, ground_truth)
      0.6666666666666666
  """
  @spec robust_accuracy(list(), list()) :: float()
  def robust_accuracy(predictions, _ground_truth) when predictions == [], do: 0.0

  def robust_accuracy(predictions, ground_truth) do
    correct =
      Enum.zip(predictions, ground_truth)
      |> Enum.count(fn {pred, truth} -> pred == truth end)

    correct / length(predictions)
  end

  # Private helpers

  defp calculate_accuracy([]), do: 0.0

  defp calculate_accuracy(results) do
    correct = Enum.count(results, fn {_pred, _label, correct?} -> correct? end)
    correct / length(results)
  end

  defp determine_severity(relative_drop) when relative_drop < 0.05, do: :low
  defp determine_severity(relative_drop) when relative_drop < 0.15, do: :moderate
  defp determine_severity(relative_drop) when relative_drop < 0.30, do: :high
  defp determine_severity(_relative_drop), do: :critical
end
