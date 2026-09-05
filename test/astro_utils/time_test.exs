defmodule AstroUtils.TimeTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Time

  doctest AstroUtils.Time

  @eps 1.0e-12

  describe "julian_centuries/1" do
    test "J2000.0 is the zero point" do
      assert Time.julian_centuries(2_451_545.0) == 0.0
    end

    test "one Julian century is 36525 days" do
      assert_in_delta Time.julian_centuries(2_451_545.0 + 36_525.0), 1.0, @eps
      assert_in_delta Time.julian_centuries(2_451_545.0 + 18_262.5), 0.5, @eps
    end

    test "dates before J2000.0 are negative" do
      assert_in_delta Time.julian_centuries(2_451_545.0 - 36_525.0), -1.0, @eps
      assert Time.julian_centuries(2_415_020.0) < 0.0
    end

    test "is linear in Julian Date" do
      for jd <- [2_400_000.5, 2_451_545.0, 2_460_000.5] do
        assert_in_delta Time.julian_centuries(jd + 36_525.0) - Time.julian_centuries(jd),
                        1.0,
                        @eps
      end
    end

    test "accepts integer Julian Dates" do
      assert_in_delta Time.julian_centuries(2_451_545), 0.0, @eps
    end
  end
end
