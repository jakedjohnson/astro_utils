defmodule AstroUtils.Matrix3 do
  @moduledoc """
  3x3 matrix operations, primarily for rotations.

  A matrix is a row-major list of three three-element lists, i.e.
  `[[r11, r12, r13], [r21, r22, r23], [r31, r32, r33]]`. Every function here
  assumes that exact shape; other shapes either raise `FunctionClauseError`
  or produce garbage rather than a friendly error.

  ## Rotation convention

  `rot_x/1`, `rot_y/1`, and `rot_z/1` return *active* (vector) rotations in a
  right-handed frame: `multiply_vector/2` rotates the vector counter-clockwise
  about the named axis by the given angle, as seen looking down that axis
  toward the origin. Angles are in **radians**; use `AstroUtils.Angle.deg_to_rad/1`
  for degree input.

  Astronomy references often tabulate the opposite (frame) convention, where
  the axes rotate and the vector stays put. `transpose/1` converts between the
  two, since rotation matrices are orthogonal and their transpose is their
  inverse.

      iex> alias AstroUtils.Matrix3
      iex> Matrix3.rot_z(:math.pi() / 2)
      ...> |> Matrix3.multiply_vector({1.0, 0.0, 0.0})
      ...> |> then(fn {x, y, z} -> {Float.round(x, 12), Float.round(y, 12), Float.round(z, 12)} end)
      {0.0, 1.0, 0.0}
  """

  @typedoc "A 3x3 matrix as a row-major list of three rows."
  @type t :: [[float()]]

  @typedoc "A 3D vector as an `{x, y, z}` tuple."
  @type vector :: {float(), float(), float()}

  @doc """
  The 3x3 identity matrix.

  ## Examples

      iex> AstroUtils.Matrix3.identity()
      [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
  """
  @spec identity() :: t()
  def identity do
    [
      [1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [0.0, 0.0, 1.0]
    ]
  end

  @doc """
  Rotation of `theta` radians about the x-axis.

  Leaves the x component unchanged and rotates y toward z.

  ## Examples

      iex> AstroUtils.Matrix3.rot_x(:math.pi())
      ...> |> AstroUtils.Matrix3.multiply_vector({0.0, 1.0, 0.0})
      ...> |> then(fn {x, y, z} -> {Float.round(x, 12), Float.round(y, 12), Float.round(z, 12)} end)
      {0.0, -1.0, 0.0}
  """
  @spec rot_x(number()) :: t()
  def rot_x(theta) when is_number(theta) do
    c = :math.cos(theta)
    s = :math.sin(theta)

    [
      [1.0, 0.0, 0.0],
      [0.0, c, -s],
      [0.0, s, c]
    ]
  end

  @doc """
  Rotation of `theta` radians about the y-axis.

  Leaves the y component unchanged and rotates z toward x.
  """
  @spec rot_y(number()) :: t()
  def rot_y(theta) when is_number(theta) do
    c = :math.cos(theta)
    s = :math.sin(theta)

    [
      [c, 0.0, s],
      [0.0, 1.0, 0.0],
      [-s, 0.0, c]
    ]
  end

  @doc """
  Rotation of `theta` radians about the z-axis.

  Leaves the z component unchanged and rotates x toward y.
  """
  @spec rot_z(number()) :: t()
  def rot_z(theta) when is_number(theta) do
    c = :math.cos(theta)
    s = :math.sin(theta)

    [
      [c, -s, 0.0],
      [s, c, 0.0],
      [0.0, 0.0, 1.0]
    ]
  end

  @doc """
  Matrix product `a · b`.

  Matrix multiplication is not commutative. When composing rotations that
  will be applied with `multiply_vector/2`, the right-most factor acts on the
  vector first, so `multiply(rot_z(c), multiply(rot_x(b), rot_z(a)))` applies
  `rot_z(a)`, then `rot_x(b)`, then `rot_z(c)`.

  Works for any 3x3 matrices, not only rotations.

  ## Examples

      iex> m = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
      iex> AstroUtils.Matrix3.multiply(m, AstroUtils.Matrix3.identity())
      [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
  """
  @spec multiply(t(), t()) :: t()
  def multiply(a, b) do
    columns = transpose(b)

    for row <- a do
      for column <- columns do
        dot_product(row, column)
      end
    end
  end

  defp dot_product(a, b) do
    a
    |> Enum.zip(b)
    |> Enum.reduce(0.0, fn {left, right}, acc -> acc + left * right end)
  end

  @doc """
  Swap rows and columns.

  For a rotation matrix the transpose is also the inverse, so this is how you
  invert a rotation without solving anything.

  ## Examples

      iex> AstroUtils.Matrix3.transpose([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]])
      [[1.0, 4.0, 7.0], [2.0, 5.0, 8.0], [3.0, 6.0, 9.0]]
  """
  @spec transpose(t()) :: t()
  def transpose([[a11, a12, a13], [a21, a22, a23], [a31, a32, a33]]) do
    [
      [a11, a21, a31],
      [a12, a22, a32],
      [a13, a23, a33]
    ]
  end

  @doc """
  Apply a matrix to a column vector, returning `m · v`.

  ## Examples

      iex> AstroUtils.Matrix3.multiply_vector(AstroUtils.Matrix3.identity(), {1.0, 2.0, 3.0})
      {1.0, 2.0, 3.0}
  """
  @spec multiply_vector(t(), vector()) :: vector()
  def multiply_vector([[r11, r12, r13], [r21, r22, r23], [r31, r32, r33]], {x, y, z}) do
    {
      r11 * x + r12 * y + r13 * z,
      r21 * x + r22 * y + r23 * z,
      r31 * x + r32 * y + r33 * z
    }
  end
end
