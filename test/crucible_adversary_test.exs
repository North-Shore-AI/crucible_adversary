defmodule CrucibleAdversaryTest do
  use ExUnit.Case
  # doctest CrucibleAdversary

  test "has version" do
    assert is_binary(CrucibleAdversary.version())
  end
end
