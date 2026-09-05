defmodule AstroUtils.Time do
  @moduledoc """
  Time-scale helpers for astronomical computation.

  Julian centuries from J2000.0 is the standard time argument for polynomial
  expressions in celestial mechanics (Meeus, IERS, IAU). J2000.0 is the epoch
  JD 2451545.0 TT, i.e. 2000 January 1 at 12:00 TT.

  This module only rescales a Julian Date; it does not convert between time
  scales. Converting UTC to TT (leap seconds plus the 32.184 s TAI offset)
  is the caller's responsibility.
  """

  @j2000 2_451_545.0
  @days_per_julian_century 36_525.0

  @doc """
  Convert a Julian Date (TT) to Julian centuries elapsed since J2000.0.

  This is the standard `T` argument used in Meeus polynomials, IERS Earth
  orientation series, and IAU precession/nutation models. Dates before
  J2000.0 give negative values; there is no clamping.

  ## Examples

      iex> AstroUtils.Time.julian_centuries(2451545.0)
      0.0

      iex> AstroUtils.Time.julian_centuries(2451545.0 + 36525.0)
      1.0

      iex> AstroUtils.Time.julian_centuries(2451545.0 - 36525.0)
      -1.0
  """
  @spec julian_centuries(number()) :: float()
  def julian_centuries(jd_tt) do
    (jd_tt - @j2000) / @days_per_julian_century
  end
end
