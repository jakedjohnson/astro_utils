defmodule AstroUtils.Coordinates do
  @moduledoc """
  Coordinate-system transforms on the sphere.

  These functions implement spherical trigonometry identities with no
  ephemeris data, process state, or I/O.
  """

  alias AstroUtils.Angle

  @doc """
  Convert an ecliptic longitude (on the ecliptic plane, lat = 0) to local
  horizontal coordinates (altitude, azimuth).

  Uses standard spherical trigonometry:

  1. ecliptic → equatorial via obliquity rotation
  2. equatorial → hour-angle via local sidereal time
  3. hour-angle + declination → altitude / azimuth

  All inputs and outputs are in **degrees**.  Azimuth convention: 0° = North,
  90° = East, increasing clockwise (standard astronomical/navigational
  convention).

  The result is the geometric direction. Ecliptic latitude is assumed to be
  zero, and no correction is applied for atmospheric refraction, parallax, or
  observer elevation.

  ## Parameters

    * `ecl_lon_deg` — ecliptic longitude in degrees (0–360; other values are
      handled by the trigonometry and need not be normalized)
    * `obliquity_deg` — obliquity of the ecliptic in degrees (~23.44 currently)
    * `lst_deg` — local sidereal time in degrees (0–360); multiply sidereal
      hours by 15 to get degrees
    * `lat_deg` — observer geographic latitude in degrees (−90 to 90, north
      positive)

  ## Returns

    `{altitude_deg, azimuth_deg}` where altitude ∈ [-90, 90] and
    azimuth ∈ [0, 360). Azimuth is not meaningful at the zenith and nadir,
    where it degenerates to `0.0`.

  ## Examples

  Seen from the equator with the vernal equinox on the meridian, the
  summer-solstice point (ecliptic longitude 90°) sits on the eastern horizon,
  north of due east by the obliquity:

      iex> {alt, az} = AstroUtils.Coordinates.ecliptic_to_horizontal(90.0, 23.44, 0.0, 0.0)
      iex> {Float.round(alt, 6), Float.round(az, 6)}
      {0.0, 66.56}
  """
  @spec ecliptic_to_horizontal(number(), number(), number(), number()) ::
          {float(), float()}
  def ecliptic_to_horizontal(ecl_lon_deg, obliquity_deg, lst_deg, lat_deg) do
    lam = Angle.deg_to_rad(ecl_lon_deg)
    eps = Angle.deg_to_rad(obliquity_deg)
    lst = Angle.deg_to_rad(lst_deg)
    phi = Angle.deg_to_rad(lat_deg)

    sin_lam = :math.sin(lam)
    cos_lam = :math.cos(lam)
    cos_eps = :math.cos(eps)
    sin_eps = :math.sin(eps)

    ra = :math.atan2(sin_lam * cos_eps, cos_lam)
    dec = :math.asin(sin_eps * sin_lam)

    ha = lst - ra

    sin_dec = :math.sin(dec)
    cos_dec = :math.cos(dec)
    sin_phi = :math.sin(phi)
    cos_phi = :math.cos(phi)
    sin_ha = :math.sin(ha)
    cos_ha = :math.cos(ha)

    alt = :math.asin(sin_dec * sin_phi + cos_dec * cos_phi * cos_ha)

    az =
      :math.atan2(
        -sin_ha * cos_dec,
        sin_dec * cos_phi - cos_ha * cos_dec * sin_phi
      )

    {Angle.rad_to_deg(alt), Angle.normalize_360(Angle.rad_to_deg(az))}
  end
end
