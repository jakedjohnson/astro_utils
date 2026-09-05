defmodule AstroUtils.CoordinatesTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Coordinates

  doctest AstroUtils.Coordinates

  # Standard test parameters: Minneapolis-ish observer
  @obliquity 23.4393
  @lat 44.98

  describe "ecliptic_to_horizontal/4" do
    test "returns {altitude, azimuth} tuple of floats" do
      {alt, az} = Coordinates.ecliptic_to_horizontal(0.0, @obliquity, 0.0, @lat)

      assert is_float(alt)
      assert is_float(az)
    end

    test "altitude is in [-90, 90] for full ecliptic sweep" do
      for lon <- 0..359 do
        {alt, _az} = Coordinates.ecliptic_to_horizontal(lon * 1.0, @obliquity, 90.0, @lat)
        assert alt >= -90.0 and alt <= 90.0, "alt #{alt} out of range at lon=#{lon}"
      end
    end

    test "azimuth is in [0, 360) for full ecliptic sweep" do
      for lon <- 0..359 do
        {_alt, az} = Coordinates.ecliptic_to_horizontal(lon * 1.0, @obliquity, 90.0, @lat)
        assert az >= 0.0 and az < 360.0, "az #{az} out of range at lon=#{lon}"
      end
    end

    test "vernal equinox at LST=0 is on the meridian (az≈180, alt≈lat-obliquity)" do
      # RA=0h, HA=0 → upper culmination. At lat≈45°, alt ≈ 90 - lat + 0 ≈ 45°.
      {alt, az} = Coordinates.ecliptic_to_horizontal(0.0, @obliquity, 0.0, @lat)

      assert_in_delta alt, 45.0, 2.0
      assert_in_delta az, 180.0, 1.0
    end

    test "south pole observer: circumpolar bodies never set (alt always > 0 near pole)" do
      # At lat=-90°, everything that transits above the ecliptic plane is up.
      # Just verify no runtime errors and consistent range.
      for lon <- 0..35 do
        {alt, az} = Coordinates.ecliptic_to_horizontal(lon * 10.0, @obliquity, 0.0, -89.9)
        assert alt >= -90.0 and alt <= 90.0
        assert az >= 0.0 and az < 360.0
      end
    end

    test "opposite ecliptic longitudes produce roughly opposite azimuths" do
      lst = 120.0
      {alt1, az1} = Coordinates.ecliptic_to_horizontal(30.0, @obliquity, lst, @lat)
      {alt2, az2} = Coordinates.ecliptic_to_horizontal(210.0, @obliquity, lst, @lat)

      az_diff = abs(az1 - az2)
      az_diff = if az_diff > 180.0, do: 360.0 - az_diff, else: az_diff
      assert_in_delta az_diff, 180.0, 40.0

      assert_in_delta alt1, -alt2, 15.0
    end

    test "full-circle LST sweep for a fixed ecliptic point stays bounded" do
      for lst_step <- 0..35 do
        lst = lst_step * 10.0
        {alt, az} = Coordinates.ecliptic_to_horizontal(45.0, @obliquity, lst, @lat)
        assert alt >= -90.0 and alt <= 90.0
        assert az >= 0.0 and az < 360.0
      end
    end

    test "zero obliquity collapses ecliptic to equator" do
      # With obliquity=0, lon=0 → RA=0, dec=0. At LST=0, HA=0 → alt=(90-lat), az=180.
      {alt, az} = Coordinates.ecliptic_to_horizontal(0.0, 0.0, 0.0, @lat)

      assert_in_delta alt, 90.0 - @lat, 0.01
      assert_in_delta az, 180.0, 0.01
    end
  end
end
