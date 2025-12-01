defmodule CrucibleAdversary.Stage do
  @moduledoc """
  Pipeline stage for adversarial robustness testing.

  Integrates CrucibleAdversary with CrucibleIR's pipeline architecture,
  enabling adversarial evaluation as a composable pipeline stage.

  ## Usage

      # As a pipeline stage
      context = %{
        experiment: %{name: "robustness_test"},
        model: MyModel,
        test_set: [{"input", :expected}],
        config: %{
          attacks: [:character_swap, :prompt_injection_basic],
          metrics: [:accuracy_drop, :asr]
        }
      }

      {:ok, updated_context} = CrucibleAdversary.Stage.run(context)

  ## Context Structure

  ### Input Context
  - `:model` (required) - Model module or function to test
  - `:test_set` (required) - List of {input, expected_output} tuples
  - `:config` (optional) - Map with:
    - `:attacks` - List of attack types (default: [:character_swap, :word_deletion])
    - `:metrics` - List of metrics to compute (default: [:accuracy_drop, :asr])
    - `:seed` - Random seed for reproducibility
    - `:attack_opts` - Additional attack options

  ### Output Context
  Original context plus:
  - `:adversarial_evaluation` - Full EvaluationResult struct
  - `:adversarial_metrics` - Extracted metrics map for quick access
  - `:adversarial_vulnerabilities` - List of identified vulnerabilities
  """

  alias CrucibleAdversary.{EvaluationResult}
  alias CrucibleAdversary.Evaluation.Robustness

  @default_attacks [:character_swap, :word_deletion]
  @default_metrics [:accuracy_drop, :asr]

  @doc """
  Executes the adversarial robustness testing stage.

  ## Parameters
    * `context` - Pipeline context map with model and test_set
    * `opts` - Optional stage options (merged with context.config)

  ## Returns
    * `{:ok, updated_context}` - Context with adversarial evaluation results

  ## Examples

      iex> context = %{
      ...>   model: fn x -> String.upcase(x) end,
      ...>   test_set: [{"hello", "HELLO"}],
      ...>   config: %{attacks: [:character_swap], metrics: [:accuracy_drop]}
      ...> }
      iex> {:ok, result} = CrucibleAdversary.Stage.run(context)
      iex> Map.has_key?(result, :adversarial_evaluation)
      true

      iex> {:ok, result} = CrucibleAdversary.Stage.run(%{}, %{})
      iex> result.adversarial_evaluation.test_set_size
      0
  """
  @spec run(map(), map()) :: {:ok, map()}
  def run(context, opts \\ %{})

  def run(context, opts) when is_map(context) and is_map(opts) do
    # Extract configuration
    config = Map.get(context, :config, %{})
    merged_config = Map.merge(config, opts)

    model = Map.get(context, :model)
    test_set = Map.get(context, :test_set, [])

    # Build evaluation options
    eval_opts = build_eval_opts(merged_config)

    # Run evaluation (always returns {:ok, evaluation})
    {:ok, evaluation} = Robustness.evaluate(model, test_set, eval_opts)
    {:ok, augment_context(context, evaluation)}
  end

  @doc """
  Returns a human-readable description of this stage.

  ## Parameters
    * `opts` - Optional configuration map

  ## Returns
    * String description of the stage configuration

  ## Examples

      iex> CrucibleAdversary.Stage.describe()
      "Adversarial robustness testing with attacks: [:character_swap, :word_deletion], metrics: [:accuracy_drop, :asr]"

      iex> CrucibleAdversary.Stage.describe(%{attacks: [:prompt_injection_basic], metrics: [:asr]})
      "Adversarial robustness testing with attacks: [:prompt_injection_basic], metrics: [:asr]"
  """
  @spec describe(map()) :: String.t()
  def describe(opts \\ %{})

  def describe(opts) when is_map(opts) do
    attacks = Map.get(opts, :attacks, @default_attacks)
    metrics = Map.get(opts, :metrics, @default_metrics)

    "Adversarial robustness testing with attacks: #{inspect(attacks)}, metrics: #{inspect(metrics)}"
  end

  # Private Functions

  defp build_eval_opts(config) do
    attacks = Map.get(config, :attacks, @default_attacks)
    metrics = Map.get(config, :metrics, @default_metrics)
    seed = Map.get(config, :seed)
    attack_opts = Map.get(config, :attack_opts, [])

    opts = [
      attacks: attacks,
      metrics: metrics,
      attack_opts: attack_opts
    ]

    if seed, do: Keyword.put(opts, :seed, seed), else: opts
  end

  defp augment_context(context, %EvaluationResult{} = evaluation) do
    context
    |> Map.put(:adversarial_evaluation, evaluation)
    |> Map.put(:adversarial_metrics, evaluation.metrics)
    |> Map.put(:adversarial_vulnerabilities, evaluation.vulnerabilities)
  end
end
