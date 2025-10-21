defmodule CrucibleAdversary.EvaluationResult do
  @moduledoc """
  Represents the result of a robustness evaluation.

  ## Fields

    * `:model` - The model being evaluated (atom or string)
    * `:test_set_size` - Number of test examples evaluated
    * `:attack_types` - List of attack types used in evaluation
    * `:metrics` - Map of calculated metrics
    * `:vulnerabilities` - List of identified vulnerabilities
    * `:timestamp` - When the evaluation was performed

  ## Examples

      iex> %CrucibleAdversary.EvaluationResult{
      ...>   model: :my_model,
      ...>   test_set_size: 100,
      ...>   attack_types: [:character_swap],
      ...>   metrics: %{accuracy_drop: 0.15}
      ...> }
      %CrucibleAdversary.EvaluationResult{
        model: :my_model,
        test_set_size: 100,
        attack_types: [:character_swap],
        metrics: %{accuracy_drop: 0.15},
        vulnerabilities: [],
        timestamp: nil
      }
  """

  @type t :: %__MODULE__{
          model: atom() | String.t(),
          test_set_size: non_neg_integer(),
          attack_types: list(atom()),
          metrics: map(),
          vulnerabilities: list(map()),
          timestamp: DateTime.t() | nil
        }

  defstruct [
    :model,
    :test_set_size,
    attack_types: [],
    metrics: %{},
    vulnerabilities: [],
    timestamp: nil
  ]
end
