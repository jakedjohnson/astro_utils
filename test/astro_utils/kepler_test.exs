defmodule AstroUtils.KeplerTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Kepler

  doctest AstroUtils.Kepler

  describe "solve_kepler/2" do
    test "M=0 yields E=0 for any eccentricity" do
      assert_in_delta Kepler.solve_kepler(0.0, 0.0), 0.0, 1.0e-12
      assert_in_delta Kepler.solve_kepler(0.0, 0.5), 0.0, 1.0e-12
      assert_in_delta Kepler.solve_kepler(0.0, 0.99), 0.0, 1.0e-12
    end

    test "M=π yields E=π (perihelion is symmetric)" do
      pi = :math.pi()
      assert_in_delta Kepler.solve_kepler(pi, 0.0), pi, 1.0e-10
      assert_in_delta Kepler.solve_kepler(pi, 0.5), pi, 1.0e-10
    end

    test "circular orbit (e=0) satisfies M=E exactly" do
      for m_frac <- [0.0, 0.25, 0.5, 0.75] do
        m_rad = m_frac * 2.0 * :math.pi()
        e_rad = Kepler.solve_kepler(m_rad, 0.0)

        assert_in_delta e_rad,
                        m_rad,
                        1.0e-12,
                        "circular orbit: E should equal M at m_frac=#{m_frac}"
      end
    end

    test "solution satisfies Kepler's equation M = E - e·sin(E)" do
      test_cases = [
        {0.5, 0.3},
        {1.2, 0.6},
        {2.8, 0.1},
        {0.1, 0.95}
      ]

      for {m_rad, e} <- test_cases do
        e_rad = Kepler.solve_kepler(m_rad, e)
        residual = abs(e_rad - e * :math.sin(e_rad) - m_rad)
        assert residual < 1.0e-11, "Kepler residual #{residual} for m=#{m_rad}, e=#{e}"
      end
    end

    test "high-eccentricity orbit (e=0.85) converges" do
      m_rad = 1.0
      e_rad = Kepler.solve_kepler(m_rad, 0.85)
      residual = abs(e_rad - 0.85 * :math.sin(e_rad) - m_rad)
      assert residual < 1.0e-11
    end

    test "result is in valid range for mean anomaly sweep" do
      for step <- 0..19 do
        m_rad = step * (:math.pi() / 10.0)
        e_rad = Kepler.solve_kepler(m_rad, 0.4)
        # Eccentric anomaly must be in [0, 2π] for M in [0, 2π]
        assert e_rad >= 0.0 and e_rad <= 2.0 * :math.pi() + 0.01,
               "e_rad=#{e_rad} out of range for m_rad=#{m_rad}"
      end
    end
  end

  describe "true_anomaly_and_radius/3" do
    test "at perihelion (E=0): v=0, r=a(1-e)" do
      a = 5.0
      e = 0.4
      {v, r} = Kepler.true_anomaly_and_radius(0.0, e, a)

      assert_in_delta v, 0.0, 1.0e-12
      assert_in_delta r, a * (1.0 - e), 1.0e-12
    end

    test "at aphelion (E=π): v=π, r=a(1+e)" do
      a = 5.0
      e = 0.4
      pi = :math.pi()
      {v, r} = Kepler.true_anomaly_and_radius(pi, e, a)

      assert_in_delta v, pi, 1.0e-12
      assert_in_delta r, a * (1.0 + e), 1.0e-12
    end

    test "circular orbit (e=0): r=a at all anomalies" do
      a = 3.0

      for step <- 0..7 do
        e_anom = step * (:math.pi() / 4.0)
        {_v, r} = Kepler.true_anomaly_and_radius(e_anom, 0.0, a)
        assert_in_delta r, a, 1.0e-12, "r should equal a for circular orbit at E=#{e_anom}"
      end
    end

    test "radius is always positive" do
      for {e_anom, e} <- [{0.5, 0.3}, {1.5, 0.6}, {2.5, 0.1}] do
        {_v, r} = Kepler.true_anomaly_and_radius(e_anom, e, 10.0)
        assert r > 0.0
      end
    end
  end

  describe "orbital_to_ecliptic/5" do
    test "zero inclination and zero longitude of ascending node preserves in-plane position" do
      # With i=0 and Ω=0, the orbital plane is the ecliptic; only ω rotates the x-axis.
      # With ω=0 as well, x_orb → x, y_orb → y directly.
      {x, y, z} = Kepler.orbital_to_ecliptic(1.0, 0.0, 0.0, 0.0, 0.0)

      assert_in_delta x, 1.0, 1.0e-12
      assert_in_delta y, 0.0, 1.0e-12
      assert_in_delta z, 0.0, 1.0e-12
    end

    test "preserves vector magnitude" do
      x_orb = 2.5
      y_orb = 1.3
      {x, y, z} = Kepler.orbital_to_ecliptic(x_orb, y_orb, 45.0, 30.0, 120.0)

      input_mag = :math.sqrt(x_orb * x_orb + y_orb * y_orb)
      output_mag = :math.sqrt(x * x + y * y + z * z)

      assert_in_delta input_mag, output_mag, 1.0e-10
    end

    test "non-zero inclination produces non-zero z" do
      {_x, _y, z} = Kepler.orbital_to_ecliptic(1.0, 0.5, 30.0, 15.0, 45.0)
      assert abs(z) > 1.0e-6
    end

    test "zero inclination produces z=0 for any ω and Ω" do
      {_x, _y, z} = Kepler.orbital_to_ecliptic(1.0, 1.0, 123.0, 0.0, 200.0)
      assert_in_delta z, 0.0, 1.0e-12
    end

    test "sample orbital elements produce ecliptic coords with known magnitude" do
      # Propagate a representative eccentric orbit and verify the
      # heliocentric radius stays within the expected semi-major-axis bounds.
      a_au = 13.69219886521367
      e = 0.3789792365116352
      m_rad = 0.5

      e_rad = Kepler.solve_kepler(m_rad, e)
      {v, r} = Kepler.true_anomaly_and_radius(e_rad, e, a_au)
      x_orb = r * :math.cos(v)
      y_orb = r * :math.sin(v)

      {x, y, z} = Kepler.orbital_to_ecliptic(x_orb, y_orb, 339.25, 6.926, 209.30)

      mag = :math.sqrt(x * x + y * y + z * z)
      assert_in_delta mag, r, 1.0e-10

      # r must be within [a(1-e), a(1+e)]
      assert r >= a_au * (1.0 - e)
      assert r <= a_au * (1.0 + e)
    end
  end
end
