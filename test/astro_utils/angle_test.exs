defmodule AstroUtils.AngleTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Angle

  doctest AstroUtils.Angle

  @eps 1.0e-9

  describe "deg_to_rad/1 and rad_to_deg/1" do
    test "roundtrip" do
      for deg <- [0.0, 45.0, 90.0, 180.0, 270.0, 360.0, -90.0] do
        assert_in_delta Angle.rad_to_deg(Angle.deg_to_rad(deg)), deg, @eps
      end
    end

    test "known values" do
      assert_in_delta Angle.deg_to_rad(180.0), :math.pi(), @eps
      assert_in_delta Angle.rad_to_deg(:math.pi()), 180.0, @eps
    end
  end

  describe "normalize_360/1" do
    test "output in [0,360) and idempotent" do
      for x <- [-1.0e6, -360.0, -180.0, -90.0, -1.0, 0.0, 1.0, 90.0, 180.0, 360.0, 720.0, 1.0e6] do
        y = Angle.normalize_360(x)
        assert y >= 0.0 and y < 360.0
        assert_in_delta Angle.normalize_360(y), y, @eps
      end
    end

    test "periodicity" do
      for x <- [-180.0, 0.0, 90.0, 180.0, 270.0],
          k <- [-100, -10, -1, 1, 10, 100] do
        assert_in_delta Angle.normalize_360(x), Angle.normalize_360(x + 360.0 * k), @eps
      end
    end

    test "spot checks" do
      assert Angle.normalize_360(0.0) == 0.0
      assert Angle.normalize_360(360.0) == 0.0
      assert Angle.normalize_360(-90.0) == 270.0
      assert Angle.normalize_360(720.0) == 0.0
    end
  end

  describe "atan2_lon/2" do
    test "known quadrants" do
      assert_in_delta Angle.atan2_lon(0.0, 1.0), 0.0, @eps
      assert_in_delta Angle.atan2_lon(1.0, 0.0), 90.0, @eps
      assert_in_delta Angle.atan2_lon(0.0, -1.0), 180.0, @eps
      assert_in_delta Angle.atan2_lon(-1.0, 0.0), 270.0, @eps
    end
  end

  describe "angular_distance/2" do
    test "symmetry and bounds" do
      for a <- [-360.0, -180.0, -90.0, 0.0, 90.0, 180.0, 360.0],
          b <- [-180.0, -90.0, 0.0, 90.0, 180.0, 360.0] do
        d1 = Angle.angular_distance(a, b)
        d2 = Angle.angular_distance(b, a)
        assert d1 >= -@eps
        assert d1 <= 180.0 + @eps
        assert_in_delta d1, d2, @eps
      end
    end

    test "spot checks" do
      assert_in_delta Angle.angular_distance(0.0, 180.0), 180.0, @eps
      assert_in_delta Angle.angular_distance(359.0, 1.0), 2.0, @eps
      assert_in_delta Angle.angular_distance(0.0, 90.0), 90.0, @eps
      assert_in_delta Angle.angular_distance(-1.0, 1.0), 2.0, @eps
    end

    test "triangle inequality" do
      for a <- [-360.0, -180.0, 0.0, 180.0, 360.0],
          b <- [-180.0, 0.0, 180.0],
          c <- [-90.0, 0.0, 90.0] do
        ab = Angle.angular_distance(a, b)
        bc = Angle.angular_distance(b, c)
        ac = Angle.angular_distance(a, c)
        assert ac <= ab + bc + @eps
      end
    end
  end

  describe "normalize_360 floating-point edge cases" do
    test "never returns exactly 360.0" do
      # IEEE 754 cancellation: a tiny negative value + 360.0 can round to 360.0.
      # Values that could trigger this in atan2-based pipelines:
      edge_cases = [360.0, -0.0, -1.0e-15, -1.0e-14, 720.0, -360.0]

      for v <- edge_cases do
        result = Angle.normalize_360(v)

        assert result >= 0.0 and result < 360.0,
               "normalize_360(#{v}) = #{result} is outside [0, 360)"
      end
    end
  end
end
