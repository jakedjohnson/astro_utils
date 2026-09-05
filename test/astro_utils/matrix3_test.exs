defmodule AstroUtils.Matrix3Test do
  use ExUnit.Case, async: true

  alias AstroUtils.Matrix3

  doctest AstroUtils.Matrix3

  @eps 1.0e-9

  defp assert_matrix_close(a, b) do
    Enum.zip(List.flatten(a), List.flatten(b))
    |> Enum.each(fn {av, bv} -> assert_in_delta av, bv, @eps end)
  end

  describe "identity/0" do
    test "multiply by identity is identity" do
      m = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
      assert_matrix_close(Matrix3.multiply(m, Matrix3.identity()), m)
      assert_matrix_close(Matrix3.multiply(Matrix3.identity(), m), m)
    end
  end

  describe "transpose/1" do
    test "double transpose is identity" do
      m = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
      assert_matrix_close(Matrix3.transpose(Matrix3.transpose(m)), m)
    end

    test "identity transpose is identity" do
      assert_matrix_close(Matrix3.transpose(Matrix3.identity()), Matrix3.identity())
    end
  end

  describe "rotation matrices" do
    test "rot_x(0) is identity" do
      assert_matrix_close(Matrix3.rot_x(0.0), Matrix3.identity())
    end

    test "rot_y(0) is identity" do
      assert_matrix_close(Matrix3.rot_y(0.0), Matrix3.identity())
    end

    test "rot_z(0) is identity" do
      assert_matrix_close(Matrix3.rot_z(0.0), Matrix3.identity())
    end

    test "rotation then inverse rotation is identity" do
      theta = :math.pi() / 4.0

      for rot <- [&Matrix3.rot_x/1, &Matrix3.rot_y/1, &Matrix3.rot_z/1] do
        r = rot.(theta)
        r_inv = rot.(-theta)
        assert_matrix_close(Matrix3.multiply(r, r_inv), Matrix3.identity())
      end
    end

    test "rotation matrix is orthogonal (R^T * R = I)" do
      theta = :math.pi() / 6.0

      for rot <- [&Matrix3.rot_x/1, &Matrix3.rot_y/1, &Matrix3.rot_z/1] do
        r = rot.(theta)
        assert_matrix_close(Matrix3.multiply(Matrix3.transpose(r), r), Matrix3.identity())
      end
    end
  end

  describe "multiply_vector/2" do
    test "identity leaves vector unchanged" do
      v = {1.0, 2.0, 3.0}
      {rx, ry, rz} = Matrix3.multiply_vector(Matrix3.identity(), v)
      assert_in_delta rx, 1.0, @eps
      assert_in_delta ry, 2.0, @eps
      assert_in_delta rz, 3.0, @eps
    end

    test "rot_z(pi/2) rotates x-axis to y-axis" do
      r = Matrix3.rot_z(:math.pi() / 2.0)
      {rx, ry, rz} = Matrix3.multiply_vector(r, {1.0, 0.0, 0.0})
      assert_in_delta rx, 0.0, @eps
      assert_in_delta ry, 1.0, @eps
      assert_in_delta rz, 0.0, @eps
    end
  end
end
