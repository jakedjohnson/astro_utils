defmodule AstroUtils.Vector do
  @moduledoc """
  3D vector operations on `{x, y, z}` tuples.

  Vectors are plain three-element tuples of floats, so they are cheap to
  build, pattern-match, and pass around. Components are unitless: the caller
  decides whether a vector holds AU, kilometres, or a direction cosine.

  Functions are total for finite float input; the only special case is
  `normalize/1` on the zero vector, which returns the zero vector rather
  than raising.

      iex> alias AstroUtils.Vector
      iex> Vector.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """

  @typedoc "A 3D vector as an `{x, y, z}` tuple."
  @type t :: {float(), float(), float()}

  @doc """
  Dot (scalar) product of two vectors.

  For unit vectors the result is the cosine of the angle between them, so
  `0.0` means orthogonal and `±1.0` means parallel or antiparallel.

  ## Examples

      iex> AstroUtils.Vector.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0

      iex> AstroUtils.Vector.dot({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      0.0
  """
  @spec dot(t(), t()) :: float()
  def dot({ax, ay, az}, {bx, by, bz}), do: ax * bx + ay * by + az * bz

  @doc """
  Cross (vector) product `a × b`, following the right-hand rule.

  The result is orthogonal to both inputs, and is the zero vector when the
  inputs are parallel. The operation is anticommutative:
  `cross(a, b) == negate(cross(b, a))`.

  ## Examples

      iex> AstroUtils.Vector.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}

      iex> AstroUtils.Vector.cross({1.0, 0.0, 0.0}, {2.0, 0.0, 0.0})
      {0.0, 0.0, 0.0}
  """
  @spec cross(t(), t()) :: t()
  def cross({ax, ay, az}, {bx, by, bz}) do
    {
      ay * bz - az * by,
      az * bx - ax * bz,
      ax * by - ay * bx
    }
  end

  @doc """
  Euclidean length (L2 norm) of a vector.

  ## Examples

      iex> AstroUtils.Vector.magnitude({3.0, 4.0, 0.0})
      5.0

      iex> AstroUtils.Vector.magnitude({0.0, 0.0, 0.0})
      0.0
  """
  @spec magnitude(t()) :: float()
  def magnitude({x, y, z}), do: :math.sqrt(x * x + y * y + z * z)

  @doc """
  Scale a vector to unit length.

  The zero vector has no direction, so it is returned unchanged instead of
  raising an arithmetic error. Check the result with `magnitude/1` if your
  caller needs to distinguish that case.

  ## Examples

      iex> AstroUtils.Vector.normalize({3.0, 4.0, 0.0})
      {0.6, 0.8, 0.0}

      iex> AstroUtils.Vector.normalize({0.0, 0.0, 0.0})
      {0.0, 0.0, 0.0}
  """
  @spec normalize(t()) :: t()
  def normalize({x, y, z}) do
    m = magnitude({x, y, z})
    if m == 0.0, do: {0.0, 0.0, 0.0}, else: {x / m, y / m, z / m}
  end

  @doc """
  Multiply every component by the scalar `s`.

  ## Examples

      iex> AstroUtils.Vector.scale({1.0, -2.0, 0.5}, 2.0)
      {2.0, -4.0, 1.0}
  """
  @spec scale(t(), number()) :: t()
  def scale({x, y, z}, s) when is_number(s), do: {x * s, y * s, z * s}

  @doc """
  Component-wise sum `a + b`.

  ## Examples

      iex> AstroUtils.Vector.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  @spec add(t(), t()) :: t()
  def add({ax, ay, az}, {bx, by, bz}), do: {ax + bx, ay + by, az + bz}

  @doc """
  Component-wise difference `a - b`.

  ## Examples

      iex> AstroUtils.Vector.subtract({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  @spec subtract(t(), t()) :: t()
  def subtract({ax, ay, az}, {bx, by, bz}), do: {ax - bx, ay - by, az - bz}

  @doc """
  Reverse a vector's direction, preserving its magnitude.

  ## Examples

      iex> AstroUtils.Vector.negate({1.0, -2.0, 3.0})
      {-1.0, 2.0, -3.0}
  """
  @spec negate(t()) :: t()
  def negate({x, y, z}), do: {-x, -y, -z}
end
