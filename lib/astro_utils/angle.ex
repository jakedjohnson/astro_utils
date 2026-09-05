defmodule AstroUtils.Angle do
  @moduledoc """
  Angle normalization, conversion, and distance functions.

  All functions take and return **degrees** unless the name says otherwise
  (`deg_to_rad/1`, `rad_to_deg/1`). Inputs may be any real value: the
  normalizing functions accept negative and out-of-range angles and fold them
  into their documented output range.

      iex> AstroUtils.Angle.normalize_360(-90.0)
      270.0
  """

  @typedoc "An angle in degrees."
  @type degree :: float()

  @full 360.0
  @half 180.0
  @pi :math.pi()

  @doc """
  Convert degrees to radians.

  ## Examples

      iex> AstroUtils.Angle.deg_to_rad(180.0)
      3.141592653589793
  """
  @spec deg_to_rad(number()) :: float()
  def deg_to_rad(deg) when is_number(deg), do: deg * @pi / 180.0

  @doc """
  Convert radians to degrees.

  ## Examples

      iex> AstroUtils.Angle.rad_to_deg(:math.pi())
      180.0
  """
  @spec rad_to_deg(number()) :: float()
  def rad_to_deg(rad) when is_number(rad), do: rad * 180.0 / @pi

  @doc """
  Normalize any angle to `[0, 360)`.

  Exactly `360.0` is never returned; values that land on the wrap point come
  back as `0.0`.

  ## Examples

      iex> AstroUtils.Angle.normalize_360(725.0)
      5.0

      iex> AstroUtils.Angle.normalize_360(-90.0)
      270.0

      iex> AstroUtils.Angle.normalize_360(360.0)
      0.0
  """
  @spec normalize_360(number()) :: degree()
  def normalize_360(angle) when is_number(angle) do
    v = angle - @full * :math.floor(angle / @full)
    v = if v < 0.0, do: v + @full, else: v
    # Safety clamp: floating-point cancellation can produce v >= 360.0 (e.g. -ε + 360.0 = 360.0).
    if v >= @full, do: 0.0, else: v
  end

  @doc """
  Compute `atan2(y, x)` and return the result in degrees in `[0, 360)`.

  Handy for recovering a longitude from the x/y components of a vector, where
  `y` is the component 90° ahead of `x`.

  ## Examples

      iex> AstroUtils.Angle.atan2_lon(1.0, 0.0)
      90.0

      iex> AstroUtils.Angle.atan2_lon(-1.0, -1.0)
      225.0
  """
  @spec atan2_lon(number(), number()) :: degree()
  def atan2_lon(y, x) when is_number(y) and is_number(x) do
    radians = :math.atan2(y, x)
    normalize_360(radians * 180.0 / @pi)
  end

  @doc """
  Unsigned minimal-arc separation between two angles, in `[0, 180]`.

  Symmetric in its arguments, and unaffected by adding whole turns to either
  input.

  ## Examples

      iex> AstroUtils.Angle.angular_distance(359.0, 1.0)
      2.0

      iex> AstroUtils.Angle.angular_distance(0.0, 190.0)
      170.0
  """
  @spec angular_distance(number(), number()) :: degree()
  def angular_distance(a, b) do
    da = abs(normalize_360(a) - normalize_360(b))
    if da > @half, do: @full - da, else: da
  end

  @doc """
  Signed shortest-path delta from `lon1` to `lon2`, in `(-180, 180]`.

  Positive means `lon2` is ahead of `lon1` in the direction of increasing
  longitude. The exactly-antipodal case is reported as `+180.0`, never
  `-180.0`, so the range is half-open on the negative side.

  ## Examples

      iex> AstroUtils.Angle.signed_delta(359.0, 1.0)
      2.0

      iex> AstroUtils.Angle.signed_delta(1.0, 359.0)
      -2.0

      iex> AstroUtils.Angle.signed_delta(0.0, 180.0)
      180.0
  """
  @spec signed_delta(number(), number()) :: degree()
  def signed_delta(lon1, lon2) do
    d = normalize_360(lon2 - lon1 + @half) - @half
    if d == -@half, do: @half, else: d
  end
end
