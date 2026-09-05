defmodule AstroUtils do
  @moduledoc """
  Math primitives for working with angles, vectors, rotations, circular data,
  Keplerian mechanics, and time-scale helper formulae.

  This module is a namespace only; the functions live in the modules below.

  | Module | Purpose |
  | --- | --- |
  | `AstroUtils.Angle` | Degree/radian conversion, normalization, angular distance, signed deltas |
  | `AstroUtils.Vector` | 3D vector algebra on `{x, y, z}` tuples |
  | `AstroUtils.Matrix3` | 3x3 rotation matrices and matrix/vector products |
  | `AstroUtils.Coordinates` | Spherical transforms, e.g. ecliptic longitude to altitude/azimuth |
  | `AstroUtils.Kepler` | Kepler's equation, true anomaly and radius, orbital-plane rotation |
  | `AstroUtils.CircularStats` | Circular mean and minimal covering arc |
  | `AstroUtils.Time` | Julian centuries from J2000.0 |
  | `AstroUtils.Math` | Rounding helper |

  ## Conventions

    * Angles are in **degrees** unless a name says `_rad` or the function is
      documented as taking radians (`AstroUtils.Matrix3` rotations and
      `AstroUtils.Kepler` anomalies).
    * Longitudes normalize to `[0, 360)`; signed deltas use `(-180, 180]`.
    * Vectors are `{x, y, z}` float tuples; 3x3 matrices are row-major lists.
    * Distances carry no unit; whatever unit goes in comes out.

  Everything is pure computation: no I/O, no processes, no runtime
  dependencies, and no ephemeris data.
  """
end
