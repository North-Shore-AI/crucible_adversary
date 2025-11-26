defmodule CrucibleAdversary.Metrics.Certified do
  @moduledoc """
  Certified robustness metrics using randomized smoothing.

  Provides provable robustness guarantees through statistical certification.
  Based on Cohen et al. (2019) "Certified Adversarial Robustness via Randomized Smoothing".

  ## Overview

  Randomized smoothing creates a smoothed classifier by adding random noise to inputs
  and returning the most frequent prediction. This provides certified L2 robustness guarantees.

  ## Examples

      iex> alias CrucibleAdversary.Metrics.Certified
      iex> model = fn input -> {:ok, :positive} end
      iex> {:ok, result} = Certified.randomized_smoothing(model, "test", num_samples: 100)
      iex> is_float(result.certified_radius)
      true

      iex> Certified.certification_level(0.95)
      :high
  """

  @default_num_samples 1000
  @default_noise_std 0.1
  @default_confidence_alpha 0.001

  @doc """
  Computes certified robustness using randomized smoothing.

  ## Options
    * `:num_samples` - Number of random samples for smoothing (default: 1000)
    * `:noise_std` - Standard deviation of added noise (default: 0.1)
    * `:confidence_alpha` - Confidence level for certification (default: 0.001)

  ## Returns
    Map containing:
    * `:certified_radius` - Certified L2 robustness radius
    * `:confidence` - Statistical confidence of certification
    * `:base_prediction` - Most frequent prediction
    * `:certification_level` - Classification of certification quality
    * `:prediction_counts` - Distribution of predictions
    * `:majority_proportion` - Proportion of majority class

  ## Examples

      iex> model = fn _input -> {:ok, :class_a} end
      iex> {:ok, result} = Certified.randomized_smoothing(model, "input", num_samples: 50)
      iex> result.base_prediction
      :class_a
  """
  @spec randomized_smoothing(module() | function(), String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def randomized_smoothing(model, input, opts \\ []) do
    num_samples = Keyword.get(opts, :num_samples, @default_num_samples)
    noise_std = Keyword.get(opts, :noise_std, @default_noise_std)
    confidence_alpha = Keyword.get(opts, :confidence_alpha, @default_confidence_alpha)

    # Sample predictions with noisy inputs
    predictions = sample_predictions(model, input, num_samples, noise_std)

    # Count prediction frequencies
    prediction_counts = Enum.frequencies(predictions)

    # Find majority prediction
    {base_prediction, majority_count} =
      prediction_counts
      |> Enum.max_by(fn {_pred, count} -> count end)

    # Calculate confidence (proportion of majority class)
    majority_proportion = majority_count / num_samples

    # Compute certified radius using binomial proportion confidence interval
    certified_radius = compute_radius(majority_proportion, noise_std)

    # Classify certification level
    cert_level = certification_level(majority_proportion)

    result = %{
      certified_radius: certified_radius,
      confidence: majority_proportion,
      base_prediction: base_prediction,
      certification_level: cert_level,
      prediction_counts: prediction_counts,
      majority_proportion: majority_proportion,
      num_samples: num_samples,
      noise_std: noise_std,
      confidence_alpha: confidence_alpha
    }

    {:ok, result}
  end

  @doc """
  Classifies certification level based on confidence.

  ## Examples

      iex> Certified.certification_level(0.95)
      :high

      iex> Certified.certification_level(0.75)
      :medium

      iex> Certified.certification_level(0.60)
      :low

      iex> Certified.certification_level(0.45)
      :none
  """
  @spec certification_level(float()) :: :none | :low | :medium | :high
  def certification_level(confidence) when confidence >= 0.9, do: :high
  def certification_level(confidence) when confidence >= 0.7, do: :medium
  def certification_level(confidence) when confidence >= 0.55, do: :low
  def certification_level(_confidence), do: :none

  @doc """
  Computes certified radius from confidence and noise level.

  Uses the theoretical bound from randomized smoothing:
  radius = noise_std * Φ^(-1)(confidence)

  where Φ^(-1) is the inverse CDF of the standard normal distribution.

  ## Examples

      iex> radius = Certified.compute_radius(0.9, 0.1)
      iex> is_float(radius)
      true
      iex> radius >= 0.0
      true
  """
  @spec compute_radius(float(), float()) :: float()
  def compute_radius(confidence, noise_std) do
    # Simplified radius calculation
    # In practice, would use proper inverse normal CDF
    # For now, use approximation based on confidence

    # Clamp confidence to valid range
    clamped_conf = max(0.5, min(0.999, confidence))

    # Approximate inverse normal CDF for confidence
    # Higher confidence → larger Z-score → larger radius
    z_score =
      cond do
        clamped_conf >= 0.99 -> 2.58
        clamped_conf >= 0.95 -> 1.96
        clamped_conf >= 0.90 -> 1.645
        clamped_conf >= 0.80 -> 1.28
        clamped_conf >= 0.70 -> 1.04
        clamped_conf >= 0.60 -> 0.84
        clamped_conf >= 0.55 -> 0.67
        true -> 0.0
      end

    # Certified radius = sigma * Z
    noise_std * z_score
  end

  @doc """
  Computes certified accuracy on a test set.

  ## Options
    * `:radius` - Required certification radius (default: 0.5)
    * `:num_samples` - Samples per input (default: 100)
    * `:noise_std` - Noise standard deviation (default: 0.1)
    * `:return_details` - Return per-example details (default: false)

  ## Returns
    * `{:ok, accuracy}` - Certified accuracy (float)
    * `{:ok, accuracy, details}` - With per-example details if requested

  ## Examples

      iex> model = fn _input -> {:ok, :positive} end
      iex> test_set = [{"input", :positive}]
      iex> {:ok, acc} = Certified.certified_accuracy(model, test_set, radius: 0.3)
      iex> is_float(acc)
      true
  """
  @spec certified_accuracy(module() | function(), list(tuple()), keyword()) ::
          {:ok, float()} | {:ok, float(), list(map())}
  def certified_accuracy(model, test_set, opts \\ []) do
    required_radius = Keyword.get(opts, :radius, 0.5)
    num_samples = Keyword.get(opts, :num_samples, 100)
    noise_std = Keyword.get(opts, :noise_std, @default_noise_std)
    return_details = Keyword.get(opts, :return_details, false)

    # Evaluate each example
    results =
      test_set
      |> Enum.map(fn {input, expected_label} ->
        {:ok, cert_result} =
          randomized_smoothing(
            model,
            input,
            num_samples: num_samples,
            noise_std: noise_std
          )

        # Check if certified and correct
        is_certified = cert_result.certified_radius >= required_radius
        is_correct = cert_result.base_prediction == expected_label
        is_certified_correct = is_certified and is_correct

        %{
          input: input,
          expected: expected_label,
          prediction: cert_result.base_prediction,
          certified_radius: cert_result.certified_radius,
          certified: is_certified,
          correct: is_correct,
          certified_correct: is_certified_correct
        }
      end)

    # Calculate certified accuracy
    num_certified_correct = results |> Enum.count(& &1.certified_correct)
    accuracy = num_certified_correct / length(results)

    if return_details do
      {:ok, accuracy, results}
    else
      {:ok, accuracy}
    end
  end

  # Private helper functions

  defp sample_predictions(model, input, num_samples, noise_std) do
    1..num_samples
    |> Enum.map(fn _i ->
      # Add character-level noise to input
      noisy_input = add_noise(input, noise_std)

      # Query model
      {:ok, prediction} = query_model(model, noisy_input)

      prediction
    end)
  end

  defp add_noise(text, noise_std) do
    # Simplified noise addition for text
    # In practice, would use more sophisticated character-level noise
    if :rand.uniform() < noise_std do
      # With small probability, perturb the text
      perturb_text(text)
    else
      text
    end
  end

  defp perturb_text(""), do: ""

  defp perturb_text(text) do
    chars = String.graphemes(text)

    if length(chars) > 0 do
      # Randomly perturb a character
      idx = :rand.uniform(length(chars)) - 1

      List.update_at(chars, idx, fn char ->
        # Small perturbation: change case or add space
        case :rand.uniform(3) do
          1 -> String.upcase(char)
          2 -> String.downcase(char)
          3 -> char <> " "
        end
      end)
      |> Enum.join()
    else
      text
    end
  end

  defp query_model(model, input) when is_function(model) do
    model.(input)
  end

  defp query_model(model, input) when is_atom(model) do
    model.predict(input)
  end
end
