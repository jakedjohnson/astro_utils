defmodule AstroUtils.Kepler do
  @moduledoc """
  Keplerian orbital mechanics.

  Pure applied mathematics for two-body orbital propagation. The usual
  sequence is: solve Kepler's equation for the eccentric anomaly, convert that
  to a true anomaly and radius, place the body in its orbital plane, then
  rotate the plane into the ecliptic frame.

      iex> alias AstroUtils.Kepler
      iex> e = 0.2
      iex> e_anom = Kepler.solve_kepler(0.5, e)
      iex> {v, r} = Kepler.true_anomaly_and_radius(e_anom, e, 1.5)
      iex> {x, y, z} = Kepler.orbital_to_ecliptic(r * :math.cos(v), r * :math.sin(v), 30.0, 10.0, 45.0)
      iex> Float.round(abs(:math.sqrt(x * x + y * y + z * z) - r), 12)
      0.0

  Angles are radians unless the argument name ends in `_deg`. Distances are in
  whatever unit the semi-major axis is given in; the argument names say AU
  because that is the common case, but nothing in the math depends on it.

  ### Accuracy caveat
  Pure Keplerian propagation ignores n-body perturbations.  For objects
  on chaotic or highly-perturbed orbits (Centaurs, Jupiter-family comets),
  expect positional errors on the order of 1–5° over multi-decade
  propagation. Higher-accuracy applications should use an ephemeris or
  numerical integration appropriate to their error budget.
  """

  alias AstroUtils.Angle

  @max_iter 50
  @tol 1.0e-12

  @doc """
  Solve Kepler's equation `M = E − e·sin(E)` for eccentric anomaly `E`
  using Newton-Raphson iteration.

  Iteration starts from `M` for `e < 0.8` and from `π` above that, and stops
  at a step size below `1.0e-12` or after 50 iterations, whichever comes
  first. It converges well within that budget for elliptical orbits; the
  iteration cap is a guard, not an expected exit.

  ## Parameters

    * `m_rad` — mean anomaly in radians
    * `e` — orbital eccentricity (0 ≤ e < 1)

  Both arguments must be floats, and `e` must be elliptical. Integers,
  parabolic orbits (`e == 1.0`), and hyperbolic orbits raise
  `FunctionClauseError`.

  ## Returns

  Eccentric anomaly in radians, in the same revolution as `m_rad`.

  ## Examples

      iex> AstroUtils.Kepler.solve_kepler(1.0, 0.0)
      1.0

      iex> e_anom = AstroUtils.Kepler.solve_kepler(0.5, 0.3)
      iex> Float.round(e_anom - 0.3 * :math.sin(e_anom), 12)
      0.5
  """
  @spec solve_kepler(float(), float()) :: float()
  def solve_kepler(m_rad, e) when is_float(m_rad) and is_float(e) and e >= 0.0 and e < 1.0 do
    e0 = if e < 0.8, do: m_rad, else: :math.pi()
    iterate(e0, m_rad, e, 0)
  end

  @doc """
  Compute true anomaly `v` (radians) and radius `r` from eccentric anomaly.

  The radius is the distance from the focus, `a·(1 − e·cos E)`: `a(1 − e)` at
  perihelion and `a(1 + e)` at aphelion.

  ## Parameters

    * `e_eccentric` — eccentric anomaly in radians
    * `e` — orbital eccentricity (0 ≤ e < 1)
    * `a_au` — semi-major axis, conventionally in AU

  ## Returns

  `{true_anomaly_rad, radius}`. The radius is in the same unit as `a_au`. The
  true anomaly is `0` at perihelion and `π` at aphelion, and stays in the same
  revolution as `e_eccentric`.

  ## Examples

      iex> AstroUtils.Kepler.true_anomaly_and_radius(0.0, 0.2, 1.0)
      {0.0, 0.8}

      iex> AstroUtils.Kepler.true_anomaly_and_radius(:math.pi(), 0.5, 2.0)
      {3.141592653589793, 3.0}
  """
  @spec true_anomaly_and_radius(float(), float(), float()) :: {float(), float()}
  def true_anomaly_and_radius(e_eccentric, e, a_au) do
    v =
      2.0 *
        :math.atan2(
          :math.sqrt(1.0 + e) * :math.sin(e_eccentric / 2.0),
          :math.sqrt(1.0 - e) * :math.cos(e_eccentric / 2.0)
        )

    r = a_au * (1.0 - e * :math.cos(e_eccentric))
    {v, r}
  end

  @doc """
  Rotate orbital-plane coordinates `(x_orb, y_orb)` into J2000 ecliptic
  XYZ using standard Euler angles.

  Orbital-plane coordinates have the perifocal x-axis pointing at perihelion,
  so `x_orb = r·cos v` and `y_orb = r·sin v`. The rotation is
  `Rz(Ω)·Rx(i)·Rz(ω)`, and being a rotation it preserves length: the returned
  vector has magnitude `r`.

  ## Parameters

    * `x_orb` — x-coordinate in the orbital plane (AU)
    * `y_orb` — y-coordinate in the orbital plane (AU)
    * `w_deg` — argument of perihelion (ω) in degrees
    * `i_deg` — inclination (i) in degrees
    * `omega_deg` — longitude of ascending node (Ω) in degrees

  ## Returns

  `{x, y, z}` in the J2000 ecliptic frame, in the same unit as the inputs.

  ## Examples

  With inclination and node both zero and the perihelion on the reference
  direction, the orbital plane is the ecliptic and coordinates pass through:

      iex> AstroUtils.Kepler.orbital_to_ecliptic(1.0, 0.0, 0.0, 0.0, 0.0)
      {1.0, 0.0, 0.0}
  """
  @spec orbital_to_ecliptic(float(), float(), float(), float(), float()) ::
          {float(), float(), float()}
  def orbital_to_ecliptic(x_orb, y_orb, w_deg, i_deg, omega_deg) do
    w = Angle.deg_to_rad(w_deg)
    i = Angle.deg_to_rad(i_deg)
    o = Angle.deg_to_rad(omega_deg)

    cos_w = :math.cos(w)
    sin_w = :math.sin(w)
    cos_i = :math.cos(i)
    sin_i = :math.sin(i)
    cos_o = :math.cos(o)
    sin_o = :math.sin(o)

    x =
      (cos_o * cos_w - sin_o * sin_w * cos_i) * x_orb +
        (-cos_o * sin_w - sin_o * cos_w * cos_i) * y_orb

    y =
      (sin_o * cos_w + cos_o * sin_w * cos_i) * x_orb +
        (-sin_o * sin_w + cos_o * cos_w * cos_i) * y_orb

    z = sin_w * sin_i * x_orb + cos_w * sin_i * y_orb

    {x, y, z}
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp iterate(e_n, m_rad, e, iter) when iter < @max_iter do
    delta = (e_n - e * :math.sin(e_n) - m_rad) / (1.0 - e * :math.cos(e_n))

    if abs(delta) < @tol do
      e_n - delta
    else
      iterate(e_n - delta, m_rad, e, iter + 1)
    end
  end

  defp iterate(e_n, _m_rad, _e, _iter), do: e_n
end
