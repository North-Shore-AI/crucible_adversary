defmodule CrucibleAdversary.AttackResult do
  @moduledoc """
  Represents the result of an adversarial attack.

  ## Fields

    * `:original` - The original input text
    * `:attacked` - The attacked/perturbed text
    * `:attack_type` - The type of attack applied (atom)
    * `:success` - Whether the attack was successful (boolean)
    * `:metadata` - Additional metadata about the attack (map)
    * `:timestamp` - When the attack was performed (DateTime)

  ## Examples

      iex> %CrucibleAdversary.AttackResult{
      ...>   original: "hello",
      ...>   attacked: "hlelo",
      ...>   attack_type: :character_swap,
      ...>   success: true
      ...> }
      %CrucibleAdversary.AttackResult{
        original: "hello",
        attacked: "hlelo",
        attack_type: :character_swap,
        success: true,
        metadata: %{},
        timestamp: nil
      }
  """

  @type t :: %__MODULE__{
          original: String.t(),
          attacked: String.t(),
          attack_type: atom(),
          success: boolean(),
          metadata: map(),
          timestamp: DateTime.t() | nil
        }

  defstruct [
    :original,
    :attacked,
    :attack_type,
    success: false,
    metadata: %{},
    timestamp: nil
  ]
end
