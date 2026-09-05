defmodule AstroUtils.Math do
  @moduledoc """
  Small numeric helpers shared across the library.
  """

  @doc """
  Round a float to `precision` decimal places.

  A thin wrapper over `Float.round/2`, mainly useful for trimming the noise
  digits that trigonometry leaves behind when comparing or displaying
  results. Ties round away from zero, so `1.5` becomes `2.0` and `-1.5`
  becomes `-2.0`.

  `float` must be a float; an integer raises `FunctionClauseError`.
  `precision` must be an integer in `0..15`; anything larger raises
  `ArgumentError`.

  ## Examples

      iex> AstroUtils.Math.roundn(1.23456, 2)
      1.23

      iex> AstroUtils.Math.roundn(1.23456)
      1.2346

      iex> AstroUtils.Math.roundn(:math.cos(:math.pi() / 2), 12)
      0.0
  """
  @spec roundn(float(), 0..15) :: float()
  def roundn(float, precision \\ 4), do: Float.round(float, precision)
end
