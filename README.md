# AstroUtils

AstroUtils is a small Elixir package for spherical geometry, vector and matrix
math, circular statistics, Keplerian mechanics, and time-scale helper
functions.

The library is pure computation: it performs no I/O, starts no processes, and
has no runtime dependencies. It ships no ephemeris data — you supply the
numbers, it does the trigonometry.

## Installation

Add `astro_utils` to your dependencies:

```elixir
def deps do
  [
    {:astro_utils, "~> 0.1.0"}
  ]
end
```

## Modules

| Module | Purpose |
|---|---|
| `AstroUtils.Angle` | Angle normalization, conversion, angular distance, and signed deltas |
| `AstroUtils.Vector` | 3D vector operations on `{x, y, z}` tuples |
| `AstroUtils.Matrix3` | 3x3 rotation matrices and vector multiplication |
| `AstroUtils.Coordinates` | Spherical coordinate transforms such as ecliptic longitude to altitude and azimuth |
| `AstroUtils.Kepler` | Kepler equation solving, true anomaly/radius conversion, and orbital-plane rotations |
| `AstroUtils.CircularStats` | Circular mean and minimal covering arc for angular samples |
| `AstroUtils.Time` | Julian-century helpers for time-dependent formulae |
| `AstroUtils.Math` | Small numeric helpers |

## Conventions

- Angles are in **degrees** except where a name says `_rad`: `AstroUtils.Matrix3`
  rotations and `AstroUtils.Kepler` anomalies take radians.
- Longitudes normalize to `[0, 360)`. Signed deltas use `(-180, 180]`.
- Vectors are `{x, y, z}` float tuples. Matrices are row-major lists of three
  three-element lists.
- Distances are unitless: whatever unit you pass in comes back out. Kepler
  argument names say AU because that is the common case, not a requirement.
- Azimuth is measured from North, increasing eastward (0° = N, 90° = E).

## Examples

Angles, including the wrap-around cases that trip up naive arithmetic:

```elixir
AstroUtils.Angle.normalize_360(725.0)
# => 5.0

AstroUtils.Angle.angular_distance(359.0, 1.0)
# => 2.0

AstroUtils.Angle.signed_delta(1.0, 359.0)
# => -2.0

AstroUtils.CircularStats.circular_mean([350.0, 10.0])
# => 0.0

AstroUtils.CircularStats.circular_mean([90.0, 270.0])
# => :undefined

AstroUtils.CircularStats.minimal_covering_arc([350.0, 10.0, 20.0])
# => {:arc, 30.0, 350.0}
```

Vectors and rotations. Rotation matrices act on vectors (an active rotation);
transpose one to invert it:

```elixir
alias AstroUtils.{Matrix3, Vector}

Vector.normalize({3.0, 4.0, 0.0})
# => {0.6, 0.8, 0.0}

Vector.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
# => {0.0, 0.0, 1.0}

Matrix3.rot_z(:math.pi() / 2) |> Matrix3.multiply_vector({1.0, 0.0, 0.0})
# => {6.123233995736766e-17, 1.0, 0.0}
```

Position a body from its orbital elements: solve Kepler's equation, convert to
a true anomaly and radius, then rotate the orbital plane into the ecliptic
frame.

```elixir
alias AstroUtils.Kepler

a_au = 2.5
e = 0.15
mean_anomaly_rad = 0.75

eccentric = Kepler.solve_kepler(mean_anomaly_rad, e)
{true_anomaly, r} = Kepler.true_anomaly_and_radius(eccentric, e, a_au)

Kepler.orbital_to_ecliptic(
  r * :math.cos(true_anomaly),
  r * :math.sin(true_anomaly),
  # argument of perihelion, inclination, longitude of ascending node (degrees)
  60.0,
  8.0,
  120.0
)
# => {-1.231328244081215, -1.8698914150208263, 0.2812653910289619}
```

`AstroUtils.Time.julian_centuries/1` produces the `T` argument that Meeus,
IERS, and IAU polynomial series expect:

```elixir
AstroUtils.Time.julian_centuries(2451545.0)
# => 0.0
```

## Documentation

Published docs live at [hexdocs.pm/astro_utils](https://hexdocs.pm/astro_utils).
Build them locally with `mix docs`.

## License

MIT. See [LICENSE](LICENSE).
