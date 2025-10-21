defmodule CrucibleAdversary.Config do
  @moduledoc """
  Configuration management for CrucibleAdversary.

  ## Fields

    * `:default_attack_rate` - Default rate for attacks (0.0-1.0)
    * `:max_perturbation_rate` - Maximum allowed perturbation rate (0.0-1.0)
    * `:random_seed` - Random seed for reproducibility (integer or nil)
    * `:logging_level` - Logging level (:debug, :info, :warn, :error)
    * `:cache_enabled` - Whether to enable caching (boolean)

  ## Examples

      iex> CrucibleAdversary.Config.default()
      %CrucibleAdversary.Config{
        default_attack_rate: 0.1,
        max_perturbation_rate: 0.3,
        random_seed: nil,
        logging_level: :info,
        cache_enabled: true
      }
  """

  @type t :: %__MODULE__{
          default_attack_rate: float(),
          max_perturbation_rate: float(),
          random_seed: integer() | nil,
          logging_level: atom(),
          cache_enabled: boolean()
        }

  defstruct default_attack_rate: 0.1,
            max_perturbation_rate: 0.3,
            random_seed: nil,
            logging_level: :info,
            cache_enabled: true

  @doc """
  Returns the default configuration.

  ## Examples

      iex> config = CrucibleAdversary.Config.default()
      iex> config.default_attack_rate
      0.1
  """
  @spec default() :: t()
  def default, do: %__MODULE__{}

  @doc """
  Validates a configuration struct.

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  ## Examples

      iex> config = CrucibleAdversary.Config.default()
      iex> CrucibleAdversary.Config.validate(config)
      :ok

      iex> config = %CrucibleAdversary.Config{default_attack_rate: -0.1}
      iex> CrucibleAdversary.Config.validate(config)
      {:error, :invalid_attack_rate}
  """
  @spec validate(t()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = config) do
    with :ok <- validate_attack_rate(config.default_attack_rate),
         :ok <- validate_max_perturbation_rate(config.max_perturbation_rate),
         :ok <- validate_logging_level(config.logging_level) do
      :ok
    end
  end

  @valid_logging_levels [:debug, :info, :warn, :error]

  defp validate_attack_rate(rate) when is_float(rate) and rate >= 0.0 and rate <= 1.0, do: :ok
  defp validate_attack_rate(_), do: {:error, :invalid_attack_rate}

  defp validate_max_perturbation_rate(rate) when is_float(rate) and rate >= 0.0 and rate <= 1.0,
    do: :ok

  defp validate_max_perturbation_rate(_), do: {:error, :invalid_max_perturbation_rate}

  defp validate_logging_level(level) when level in @valid_logging_levels, do: :ok
  defp validate_logging_level(_), do: {:error, :invalid_logging_level}
end
