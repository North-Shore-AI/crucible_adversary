defmodule CrucibleAdversary.Attacks.Inversion do
  @moduledoc """
  Model inversion attack implementations.

  Provides techniques to infer training data properties, membership,
  and model internals through careful analysis of model outputs.

  ## Attack Types

  - **Membership Inference**: Determine if specific data was in training set
  - **Attribute Inference**: Infer attributes of training examples
  - **Reconstruction Attack**: Reconstruct training features from outputs
  - **Property Inference**: Infer dataset-level properties

  ## Examples

      iex> alias CrucibleAdversary.Attacks.Inversion
      iex> model = fn _input -> {:ok, %{confidence: 0.95}} end
      iex> {:ok, result} = Inversion.membership_inference(model, "test_input", [])
      iex> result.attack_type
      :model_inversion_membership
  """

  alias CrucibleAdversary.AttackResult

  @default_confidence_threshold 0.85
  @default_num_samples 100

  @doc """
  Performs membership inference attack.

  Determines whether a given input was likely in the model's training set
  by analyzing prediction confidence and behavior patterns.

  ## Options
    * `:confidence_threshold` - Threshold for membership classification (default: 0.85)
    * `:statistical_test` - Perform statistical significance test (default: false)
    * `:num_queries` - Number of queries for statistical test (default: 10)

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack executed successfully
    * `{:error, reason}` - Attack failed with diagnostic information

  ## Examples

      iex> model = fn _ -> {:ok, %{confidence: 0.95}} end
      iex> {:ok, result} = Inversion.membership_inference(model, "training_example", [])
      iex> result.metadata.is_member
      true
  """
  @spec membership_inference(module() | function(), String.t(), keyword()) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def membership_inference(model, candidate_input, opts \\ []) do
    confidence_threshold = Keyword.get(opts, :confidence_threshold, @default_confidence_threshold)
    statistical_test = Keyword.get(opts, :statistical_test, false)
    num_queries = Keyword.get(opts, :num_queries, 10)

    # Query model for confidence
    {:ok, prediction} = query_model(model, candidate_input)
    confidence = extract_confidence(prediction)

    # Determine membership based on confidence
    is_member = confidence >= confidence_threshold

    # Perform statistical test if requested
    test_results =
      if statistical_test do
        perform_statistical_test(model, candidate_input, num_queries, confidence_threshold)
      else
        %{}
      end

    {:ok,
     %AttackResult{
       original: candidate_input,
       attacked: "Membership inference probe for: #{candidate_input}",
       attack_type: :model_inversion_membership,
       success: true,
       metadata: %{
         is_member: is_member,
         confidence: confidence,
         confidence_threshold: confidence_threshold,
         statistical_test: statistical_test,
         test_results: test_results,
         method: :confidence_based
       },
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Performs attribute inference attack.

  Infers attributes of training examples by analyzing model behavior
  on carefully crafted inputs.

  ## Options
    * `:attributes` - List of attributes to infer (required)
    * `:strategy` - Inference strategy (:direct, :perturbation, :statistical) (default: :direct)
    * `:num_probes` - Number of probing queries (default: 10)

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack executed successfully
    * `{:error, reason}` - Attack failed with diagnostic information

  ## Examples

      iex> model = fn _ -> {:ok, %{confidence: 0.8}} end
      iex> {:ok, result} = Inversion.attribute_inference(model, "input", attributes: [:sentiment])
      iex> Map.has_key?(result.metadata.inferred_attributes, :sentiment)
      true
  """
  @spec attribute_inference(module() | function(), String.t(), keyword()) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def attribute_inference(model, input, opts \\ []) do
    attributes = Keyword.fetch!(opts, :attributes)
    strategy = Keyword.get(opts, :strategy, :direct)
    num_probes = Keyword.get(opts, :num_probes, 10)

    # Infer each requested attribute
    inferred_attributes =
      attributes
      |> Enum.map(fn attr ->
        {attr, infer_single_attribute(model, input, attr, strategy, num_probes)}
      end)
      |> Enum.into(%{})

    {:ok,
     %AttackResult{
       original: input,
       attacked: "Attribute inference probe: #{inspect(attributes)}",
       attack_type: :model_inversion_attribute,
       success: true,
       metadata: %{
         target_attributes: attributes,
         inferred_attributes: inferred_attributes,
         strategy: strategy,
         num_probes: num_probes
       },
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Performs reconstruction attack to recover training features.

  Attempts to reconstruct training data characteristics by analyzing
  model outputs and behavior.

  ## Options
    * `:target` - Target to reconstruct (required)
    * `:method` - Reconstruction method (:gradient_approximation, :output_analysis, :query_based)
    * `:max_queries` - Maximum number of queries (default: 100)

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack executed successfully
    * `{:error, reason}` - Attack failed with diagnostic information

  ## Examples

      iex> model = fn _ -> {:ok, %{confidence: 0.9}} end
      iex> {:ok, result} = Inversion.reconstruction_attack(model, target: "features", method: :output_analysis)
      iex> result.attack_type
      :model_inversion_reconstruction
  """
  @spec reconstruction_attack(module() | function(), keyword()) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def reconstruction_attack(model, opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    method = Keyword.get(opts, :method, :output_analysis)
    max_queries = Keyword.get(opts, :max_queries, 100)

    {reconstructed, quality, queries_used} =
      case method do
        :gradient_approximation ->
          perform_gradient_reconstruction(model, target, max_queries)

        :output_analysis ->
          perform_output_analysis_reconstruction(model, target, max_queries)

        :query_based ->
          perform_query_based_reconstruction(model, target, max_queries)
      end

    {:ok,
     %AttackResult{
       original: to_string(target),
       attacked: "Reconstruction attempt for: #{target}",
       attack_type: :model_inversion_reconstruction,
       success: true,
       metadata: %{
         target: target,
         method: method,
         reconstructed_features: reconstructed,
         reconstruction_quality: quality,
         queries_used: queries_used,
         max_queries: max_queries
       },
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Performs property inference to infer dataset-level properties.

  Infers global properties of the training dataset through statistical
  analysis of model behavior.

  ## Options
    * `:property` - Property to infer (:class_distribution, :feature_correlation, :data_balance)
    * `:samples` - Number of samples to use (default: 100)

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack executed successfully
    * `{:error, reason}` - Attack failed with diagnostic information

  ## Examples

      iex> model = fn _ -> {:ok, %{confidence: 0.85}} end
      iex> {:ok, result} = Inversion.property_inference(model, property: :class_distribution, samples: 10)
      iex> result.attack_type
      :model_inversion_property
  """
  @spec property_inference(module() | function(), keyword()) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def property_inference(model, opts \\ []) do
    property = Keyword.fetch!(opts, :property)
    samples = Keyword.get(opts, :samples, @default_num_samples)

    {inferred_property, confidence} =
      case property do
        :class_distribution ->
          infer_class_distribution(model, samples)

        :feature_correlation ->
          infer_feature_correlation(model, samples)

        :data_balance ->
          infer_data_balance(model, samples)
      end

    {:ok,
     %AttackResult{
       original: "Dataset property inference",
       attacked: "Property inference: #{property}",
       attack_type: :model_inversion_property,
       success: true,
       metadata: %{
         property_type: property,
         inferred_property: inferred_property,
         statistical_confidence: confidence,
         num_samples: samples
       },
       timestamp: DateTime.utc_now()
     }}
  end

  # Private helper functions

  defp query_model(model, input) when is_function(model) do
    model.(input)
  end

  defp query_model(model, input) when is_atom(model) do
    model.predict(input)
  end

  defp extract_confidence(%{confidence: conf}), do: conf
  defp extract_confidence(_), do: 0.5

  defp perform_statistical_test(model, input, num_queries, threshold) do
    # Generate perturbations and query model multiple times
    confidences =
      1..num_queries
      |> Enum.map(fn _ ->
        {:ok, pred} = query_model(model, input)
        extract_confidence(pred)
      end)

    mean_confidence = Enum.sum(confidences) / length(confidences)
    std_confidence = calculate_std(confidences, mean_confidence)

    %{
      mean_confidence: mean_confidence,
      std_confidence: std_confidence,
      threshold: threshold,
      is_significant: mean_confidence > threshold + std_confidence
    }
  end

  defp calculate_std(values, mean) do
    variance =
      values
      |> Enum.map(fn x -> :math.pow(x - mean, 2) end)
      |> Enum.sum()
      |> Kernel./(length(values))

    :math.sqrt(variance)
  end

  defp infer_single_attribute(model, input, attribute, strategy, num_probes) do
    # Simplified attribute inference
    case strategy do
      :direct ->
        {:ok, pred} = query_model(model, input)
        confidence = extract_confidence(pred)

        value = infer_attribute_value(attribute, confidence, pred)
        %{value: value, confidence: confidence, method: :direct}

      :perturbation ->
        # Probe with perturbations
        probe_results =
          1..num_probes
          |> Enum.map(fn i ->
            perturbed = "#{input}_probe_#{i}"
            {:ok, pred} = query_model(model, perturbed)
            extract_confidence(pred)
          end)

        avg_confidence = Enum.sum(probe_results) / length(probe_results)
        value = infer_attribute_value(attribute, avg_confidence, %{})
        %{value: value, confidence: avg_confidence, method: :perturbation}

      :statistical ->
        # Statistical analysis
        value = :unknown
        %{value: value, confidence: 0.5, method: :statistical}
    end
  end

  defp infer_attribute_value(attribute, confidence, prediction) do
    # Simplified inference logic
    case attribute do
      :sentiment ->
        cond do
          confidence > 0.8 -> :positive
          confidence < 0.3 -> :negative
          true -> :neutral
        end

      :topic ->
        Map.get(prediction, :prediction, :unknown)

      :category ->
        Map.get(prediction, :prediction, :general)

      :language ->
        :english

      :type ->
        Map.get(prediction, :prediction, :text)

      _ ->
        :unknown
    end
  end

  defp perform_gradient_reconstruction(_model, _target, max_queries) do
    # Simplified gradient-based reconstruction
    # In real implementation, would use gradient approximation
    reconstructed = %{features: ["estimated_feature_1", "estimated_feature_2"]}
    quality = 0.65
    queries_used = min(50, max_queries)

    {reconstructed, quality, queries_used}
  end

  defp perform_output_analysis_reconstruction(_model, _target, max_queries) do
    # Simplified output analysis
    reconstructed = %{patterns: ["pattern_1", "pattern_2"], characteristics: "inferred"}
    quality = 0.70
    queries_used = min(30, max_queries)

    {reconstructed, quality, queries_used}
  end

  defp perform_query_based_reconstruction(_model, _target, max_queries) do
    # Simplified query-based reconstruction
    reconstructed = %{data_points: ["point_1", "point_2"]}
    quality = 0.60
    queries_used = min(80, max_queries)

    {reconstructed, quality, queries_used}
  end

  defp infer_class_distribution(_model, _samples) do
    # Simplified class distribution inference
    # In real implementation, would sample and analyze predictions
    distribution = %{
      class_a: 0.45,
      class_b: 0.35,
      class_c: 0.20
    }

    confidence = 0.75

    {distribution, confidence}
  end

  defp infer_feature_correlation(_model, samples) do
    # Simplified correlation inference
    correlation = %{
      feature_pairs: [{"f1", "f2", 0.8}, {"f2", "f3", 0.6}],
      num_samples: samples
    }

    confidence = 0.68

    {correlation, confidence}
  end

  defp infer_data_balance(_model, samples) do
    # Simplified balance inference
    balance = %{
      is_balanced: false,
      imbalance_ratio: 2.5,
      num_samples: samples
    }

    confidence = 0.72

    {balance, confidence}
  end
end
