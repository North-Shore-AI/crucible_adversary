defmodule CrucibleAdversary.Composition do
  @moduledoc """
  Attack composition and chaining capabilities.

  Enables sophisticated multi-stage attacks by combining multiple
  attack types in sequences or parallel configurations.

  ## Composition Patterns

  - **Sequential (Chain)**: Execute attacks one after another
  - **Parallel**: Execute multiple attacks and collect all results
  - **Best-of**: Execute multiple attacks and select the best result
  - **Conditional**: Execute attacks based on conditions

  ## Examples

      iex> alias CrucibleAdversary.Composition
      iex> chain = Composition.chain([{:character_swap, rate: 0.1}, {:word_deletion, rate: 0.1}])
      iex> {:ok, result} = Composition.execute(chain, "Test input")
      iex> result.attack_type
      :composition_chain

      iex> {:ok, results} = Composition.execute_parallel([{:character_swap, []}], "input")
      iex> is_list(results)
      true
  """

  alias CrucibleAdversary.AttackResult

  @doc """
  Creates a sequential chain of attacks.

  Attacks are executed in order, with the output of each attack
  becoming the input to the next.

  ## Parameters
    * `attack_specs` - List of {attack_type, opts} tuples

  ## Returns
    List representing the attack chain

  ## Examples

      iex> chain = Composition.chain([
      ...>   {:character_swap, rate: 0.1},
      ...>   {:word_deletion, rate: 0.2}
      ...> ])
      iex> is_list(chain)
      true
  """
  @spec chain(list(tuple())) :: list(tuple())
  def chain(attack_specs) when is_list(attack_specs) do
    attack_specs
  end

  @doc """
  Executes a chain of attacks on input.

  ## Parameters
    * `chain` - Attack chain created by `chain/1`
    * `input` - Input text to attack

  ## Returns
    * `{:ok, %AttackResult{}}` - Result of chain execution
    * `{:error, reason}` - Execution failed

  ## Examples

      iex> chain = Composition.chain([{:character_swap, rate: 0.1, seed: 42}])
      iex> {:ok, result} = Composition.execute(chain, "test")
      iex> result.attack_type
      :composition_chain
  """
  @spec execute(list(tuple()), String.t()) :: {:ok, AttackResult.t()} | {:error, term()}
  def execute([], input) do
    # Empty chain - return no-op result
    {:ok,
     %AttackResult{
       original: input,
       attacked: input,
       attack_type: :composition_chain,
       success: true,
       metadata: %{
         intermediate_results: [],
         chain_length: 0
       },
       timestamp: DateTime.utc_now()
     }}
  end

  def execute(chain, input) when is_list(chain) do
    # Execute attacks in sequence
    {final_output, intermediate_results} =
      Enum.reduce(chain, {input, []}, fn {attack_type, opts}, {current_input, results} ->
        opts_with_type = Keyword.put(opts, :type, attack_type)

        case CrucibleAdversary.attack(current_input, opts_with_type) do
          {:ok, attack_result} ->
            {attack_result.attacked, results ++ [attack_result]}

          {:error, _reason} ->
            # On error, keep current input and continue
            {current_input, results}
        end
      end)

    {:ok,
     %AttackResult{
       original: input,
       attacked: final_output,
       attack_type: :composition_chain,
       success: true,
       metadata: %{
         intermediate_results: intermediate_results,
         chain_length: length(chain)
       },
       timestamp: DateTime.utc_now()
     }}
  end

  @doc """
  Creates a parallel attack specification.

  All attacks will be executed on the same input.

  ## Parameters
    * `attack_specs` - List of {attack_type, opts} tuples

  ## Returns
    List representing parallel attacks

  ## Examples

      iex> parallel = Composition.parallel([
      ...>   {:character_swap, rate: 0.1},
      ...>   {:word_deletion, rate: 0.1}
      ...> ])
      iex> is_list(parallel)
      true
  """
  @spec parallel(list(tuple())) :: list(tuple())
  def parallel(attack_specs) when is_list(attack_specs) do
    attack_specs
  end

  @doc """
  Executes attacks in parallel on the same input.

  ## Parameters
    * `parallel_spec` - Parallel attack specification
    * `input` - Input text to attack

  ## Returns
    * `{:ok, list(%AttackResult{})}` - List of all attack results
    * `{:error, reason}` - Execution failed

  ## Examples

      iex> {:ok, results} = Composition.execute_parallel([{:character_swap, []}], "input")
      iex> is_list(results)
      true
  """
  @spec execute_parallel(list(tuple()), String.t()) ::
          {:ok, list(AttackResult.t())} | {:error, term()}
  def execute_parallel(parallel_spec, input) when is_list(parallel_spec) do
    results =
      parallel_spec
      |> Enum.map(fn {attack_type, opts} ->
        opts_with_type = Keyword.put(opts, :type, attack_type)

        case CrucibleAdversary.attack(input, opts_with_type) do
          {:ok, result} -> result
          {:error, _reason} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, results}
  end

  @doc """
  Executes multiple attacks and selects the best result.

  ## Parameters
    * `attack_specs` - List of attack specifications
    * `input` - Input text
    * `selector` - Function to select best result (optional)

  ## Returns
    * `{:ok, %AttackResult{}}` - Best attack result
    * `{:error, reason}` - Execution failed

  ## Examples

      iex> selector = fn results -> List.first(results) end
      iex> {:ok, result} = Composition.best_of([{:character_swap, []}], "test", selector)
      iex> is_map(result)
      true
  """
  @spec best_of(list(tuple()), String.t(), function() | nil) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def best_of(attack_specs, input, selector \\ nil) do
    {:ok, results} = execute_parallel(attack_specs, input)

    selector_fn = selector || (&default_selector/1)
    best_result = selector_fn.(results)

    {:ok, best_result}
  end

  @doc """
  Conditionally executes an attack based on a predicate.

  ## Parameters
    * `attack_spec` - {attack_type, opts} tuple
    * `input` - Input text
    * `condition` - Function that returns true/false

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack result or no-op
    * `{:error, reason}` - Execution failed

  ## Examples

      iex> condition = fn input -> String.length(input) > 5 end
      iex> {:ok, result} = Composition.conditional({:character_swap, []}, "long text", condition)
      iex> result.attack_type == :character_swap
      true
  """
  @spec conditional(tuple(), String.t(), function()) ::
          {:ok, AttackResult.t()} | {:error, term()}
  def conditional({attack_type, opts}, input, condition) when is_function(condition) do
    if condition.(input) do
      # Execute attack
      opts_with_type = Keyword.put(opts, :type, attack_type)
      CrucibleAdversary.attack(input, opts_with_type)
    else
      # Skip attack - return no-op
      {:ok,
       %AttackResult{
         original: input,
         attacked: input,
         attack_type: attack_type,
         success: true,
         metadata: %{
           skipped: true,
           reason: :condition_not_met
         },
         timestamp: DateTime.utc_now()
       }}
    end
  end

  # Private helper functions

  defp default_selector(results) when is_list(results) and results != [] do
    # Default: select result with longest attacked output
    Enum.max_by(results, fn r -> String.length(r.attacked) end)
  end

  defp default_selector(_results) do
    # Fallback for empty results
    %AttackResult{
      original: "",
      attacked: "",
      attack_type: :composition_best_of,
      success: false,
      metadata: %{error: :no_results},
      timestamp: DateTime.utc_now()
    }
  end
end
