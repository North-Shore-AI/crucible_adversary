defmodule CrucibleAdversary do
  @moduledoc """
  CrucibleAdversary - Adversarial Testing and Robustness Evaluation Framework

  Main API for adversarial testing of AI models. Provides a comprehensive suite
  of attacks, evaluation metrics, and robustness testing capabilities.

  ## Quick Start

      # Character-level attack
      {:ok, result} = CrucibleAdversary.attack("Hello world", type: :character_swap, rate: 0.2)

      # Evaluate model robustness
      model = fn input -> String.upcase(input) end
      test_set = [{"hello", "HELLO"}, {"world", "WORLD"}]
      {:ok, eval} = CrucibleAdversary.evaluate(model, test_set,
        attacks: [:character_swap, :word_deletion],
        metrics: [:accuracy_drop, :asr]
      )

  ## Modules

  - `CrucibleAdversary.Perturbations.Character` - Character-level attacks
  - `CrucibleAdversary.Perturbations.Word` - Word-level attacks
  - `CrucibleAdversary.Evaluation.Robustness` - Robustness evaluation
  - `CrucibleAdversary.Metrics.*` - Various robustness metrics

  ## Available Attack Types

  Character-level:
  - `:character_swap` - Swap adjacent characters
  - `:character_delete` - Delete random characters
  - `:character_insert` - Insert random characters
  - `:homoglyph` - Unicode homoglyph substitution
  - `:keyboard_typo` - Realistic keyboard typos

  Word-level:
  - `:word_deletion` - Delete random words
  - `:word_insertion` - Insert random words
  - `:synonym_replacement` - Replace with synonyms
  - `:word_shuffle` - Shuffle word order

  Semantic-level:
  - `:semantic_paraphrase` - Paraphrase while preserving meaning
  - `:semantic_back_translate` - Back-translation simulation
  - `:semantic_sentence_reorder` - Sentence order shuffling
  - `:semantic_formality_change` - Formality level changes

  Prompt Injection:
  - `:prompt_injection_basic` - Direct instruction override
  - `:prompt_injection_overflow` - Context window flooding
  - `:prompt_injection_delimiter` - Delimiter confusion
  - `:prompt_injection_template` - Template variable exploitation

  Jailbreak:
  - `:jailbreak_roleplay` - Persona-based bypass
  - `:jailbreak_context_switch` - Context manipulation
  - `:jailbreak_encode` - Obfuscation techniques
  - `:jailbreak_hypothetical` - Hypothetical scenario framing

  Data Extraction:
  - `:data_extraction_repetition` - Repetition-based data extraction
  - `:data_extraction_memorization` - Memorization probing
  - `:data_extraction_pii` - PII extraction attempts
  - `:data_extraction_context_confusion` - Context boundary exploitation

  ## Available Metrics

  - `:accuracy_drop` - Accuracy degradation metrics
  - `:asr` - Attack success rate
  - `:consistency` - Output consistency
  """

  alias CrucibleAdversary.AttackResult
  alias CrucibleAdversary.Attacks.Extraction
  alias CrucibleAdversary.Attacks.Injection
  alias CrucibleAdversary.Attacks.Jailbreak
  alias CrucibleAdversary.Config
  alias CrucibleAdversary.Evaluation.Robustness
  alias CrucibleAdversary.EvaluationResult
  alias CrucibleAdversary.Perturbations.Character
  alias CrucibleAdversary.Perturbations.Semantic
  alias CrucibleAdversary.Perturbations.Word

  @doc """
  Performs a single adversarial attack on input text.

  ## Parameters
    * `input` - Text to attack
    * `opts` - Options including:
      * `:type` - Attack type (required)
      * Other attack-specific options

  ## Returns
    * `{:ok, %AttackResult{}}` - Attack executed successfully
    * `{:error, reason}` - Attack failed with diagnostic information

  ## Examples

      iex> {:ok, result} = CrucibleAdversary.attack("Hello world", type: :character_swap, rate: 0.2, seed: 42)
      iex> result.attack_type
      :character_swap

      iex> CrucibleAdversary.attack("test", type: :invalid)
      {:error, {:unknown_attack_type, :invalid}}
  """
  @spec attack(String.t(), keyword()) :: {:ok, AttackResult.t()} | {:error, term()}
  @attack_dispatch %{
    character_swap: {Character, :swap},
    character_delete: {Character, :delete},
    character_insert: {Character, :insert},
    homoglyph: {Character, :homoglyph},
    keyboard_typo: {Character, :keyboard_typo},
    word_deletion: {Word, :delete},
    word_insertion: {Word, :insert},
    synonym_replacement: {Word, :synonym_replace},
    word_shuffle: {Word, :shuffle},
    semantic_paraphrase: {Semantic, :paraphrase},
    semantic_back_translate: {Semantic, :back_translate},
    semantic_sentence_reorder: {Semantic, :sentence_reorder},
    semantic_formality_change: {Semantic, :formality_change},
    prompt_injection_basic: {Injection, :basic},
    prompt_injection_overflow: {Injection, :context_overflow},
    prompt_injection_delimiter: {Injection, :delimiter_attack},
    prompt_injection_template: {Injection, :template_injection},
    jailbreak_roleplay: {Jailbreak, :roleplay},
    jailbreak_context_switch: {Jailbreak, :context_switch},
    jailbreak_encode: {Jailbreak, :encode},
    jailbreak_hypothetical: {Jailbreak, :hypothetical},
    data_extraction_repetition: {Extraction, :repetition_attack},
    data_extraction_memorization: {Extraction, :memorization_probe},
    data_extraction_pii: {Extraction, :pii_extraction},
    data_extraction_context_confusion: {Extraction, :context_confusion}
  }

  def attack(input, opts) do
    attack_type = Keyword.fetch!(opts, :type)

    case Map.get(@attack_dispatch, attack_type) do
      {module, function} -> apply(module, function, [input, opts])
      nil -> {:error, {:unknown_attack_type, attack_type}}
    end
  end

  @doc """
  Performs multiple attacks on a batch of inputs.

  ## Parameters
    * `inputs` - List of texts to attack
    * `opts` - Options including:
      * `:types` - List of attack types (default: [:character_swap])
      * Other attack-specific options

  ## Returns
    * `{:ok, list(AttackResult.t())}` - Collected results from all attacks
    * `{:error, reason}` - Failure while executing the batch

  ## Examples

      iex> inputs = ["hello", "world"]
      iex> {:ok, results} = CrucibleAdversary.attack_batch(inputs, types: [:character_swap], seed: 42)
      iex> length(results)
      2
  """
  @spec attack_batch(list(String.t()), keyword()) ::
          {:ok, list(AttackResult.t())} | {:error, term()}
  def attack_batch(inputs, opts \\ [])

  def attack_batch([], _opts) do
    {:ok, []}
  end

  def attack_batch(inputs, opts) do
    types = Keyword.get(opts, :types, [:character_swap])

    results =
      for input <- inputs,
          type <- types do
        opts_with_type = Keyword.put(opts, :type, type)
        {:ok, result} = attack(input, opts_with_type)
        result
      end

    {:ok, results}
  end

  @doc """
  Evaluates model robustness against adversarial attacks.

  Delegates to CrucibleAdversary.Evaluation.Robustness.evaluate/3

  ## Parameters
    * `model` - Model module or function
    * `test_set` - List of {input, expected_output} tuples
    * `opts` - Evaluation options

  ## Returns
    * `{:ok, %EvaluationResult{}}` - Completed evaluation with metrics
    * `{:error, reason}` - Evaluation failed with the given reason

  ## Examples

      iex> model = fn input -> String.upcase(input) end
      iex> test_set = [{"hello", "HELLO"}]
      iex> {:ok, result} = CrucibleAdversary.evaluate(model, test_set, seed: 42)
      iex> result.test_set_size
      1
  """
  @spec evaluate(module() | function(), list(tuple()), keyword()) ::
          {:ok, EvaluationResult.t()} | {:error, term()}
  def evaluate(model, test_set, opts \\ []) do
    Robustness.evaluate(model, test_set, opts)
  end

  @doc """
  Returns the current configuration.

  ## Examples

      iex> config = CrucibleAdversary.Config.default()
      iex> config.default_attack_rate
      0.1
  """
  @spec config() :: Config.t()
  def config do
    Application.get_env(:crucible_adversary, :config, Config.default())
  end

  @doc """
  Sets configuration.

  ## Examples

      iex> CrucibleAdversary.configure(default_attack_rate: 0.15)
      :ok

      iex> config = %CrucibleAdversary.Config{default_attack_rate: 0.2}
      iex> CrucibleAdversary.configure(config)
      :ok
  """
  @spec configure(Config.t() | keyword()) :: :ok
  def configure(%Config{} = config) do
    Application.put_env(:crucible_adversary, :config, config)
  end

  def configure(opts) when is_list(opts) do
    config = struct(Config.default(), opts)
    configure(config)
  end

  @doc """
  Returns version information.

  ## Examples

      iex> version = CrucibleAdversary.version()
      iex> is_binary(version)
      true
  """
  @spec version() :: String.t()
  def version do
    Application.spec(:crucible_adversary, :vsn) |> to_string()
  end
end
