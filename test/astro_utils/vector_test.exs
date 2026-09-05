defmodule AstroUtils.VectorTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Vector

  doctest AstroUtils.Vector

  @eps 1.0e-9

  describe "dot/2" do
    test "orthogonal vectors" do
      assert_in_delta Vector.dot({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}), 0.0, @eps
    end

    test "parallel vectors" do
      assert_in_delta Vector.dot({1.0, 0.0, 0.0}, {3.0, 0.0, 0.0}), 3.0, @eps
    end

    test "general case" do
      assert_in_delta Vector.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}), 32.0, @eps
    end
  end

  describe "cross/2" do
    test "x cross y = z" do
      assert Vector.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}) == {0.0, 0.0, 1.0}
    end

    test "parallel vectors give zero" do
      assert Vector.cross({1.0, 0.0, 0.0}, {2.0, 0.0, 0.0}) == {0.0, 0.0, 0.0}
    end

    test "anti-commutativity" do
      a = {1.0, 2.0, 3.0}
      b = {4.0, 5.0, 6.0}
      {cx, cy, cz} = Vector.cross(a, b)
      {nx, ny, nz} = Vector.cross(b, a)
      assert_in_delta cx, -nx, @eps
      assert_in_delta cy, -ny, @eps
      assert_in_delta cz, -nz, @eps
    end
  end

  describe "magnitude/1" do
    test "unit vectors" do
      assert_in_delta Vector.magnitude({1.0, 0.0, 0.0}), 1.0, @eps
    end

    test "general case" do
      assert_in_delta Vector.magnitude({3.0, 4.0, 0.0}), 5.0, @eps
    end

    test "zero vector" do
      assert_in_delta Vector.magnitude({0.0, 0.0, 0.0}), 0.0, @eps
    end
  end

  describe "normalize/1" do
    test "unit vector unchanged" do
      {x, y, z} = Vector.normalize({1.0, 0.0, 0.0})
      assert_in_delta x, 1.0, @eps
      assert_in_delta y, 0.0, @eps
      assert_in_delta z, 0.0, @eps
    end

    test "result has magnitude 1" do
      assert_in_delta Vector.magnitude(Vector.normalize({3.0, 4.0, 5.0})), 1.0, @eps
    end

    test "zero vector returns zero" do
      assert Vector.normalize({0.0, 0.0, 0.0}) == {0.0, 0.0, 0.0}
    end
  end

  describe "scale/2" do
    test "doubles" do
      assert Vector.scale({1.0, 2.0, 3.0}, 2.0) == {2.0, 4.0, 6.0}
    end

    test "zero scalar" do
      assert Vector.scale({1.0, 2.0, 3.0}, 0) == {0.0, 0.0, 0.0}
    end
  end

  describe "add/2" do
    test "basic addition" do
      assert Vector.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}) == {5.0, 7.0, 9.0}
    end
  end

  describe "subtract/2" do
    test "basic subtraction" do
      assert Vector.subtract({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0}) == {3.0, 3.0, 3.0}
    end

    test "self subtraction is zero" do
      v = {1.0, 2.0, 3.0}
      assert Vector.subtract(v, v) == {0.0, 0.0, 0.0}
    end
  end

  describe "negate/1" do
    test "negates all components" do
      assert Vector.negate({1.0, -2.0, 3.0}) == {-1.0, 2.0, -3.0}
    end

    test "double negate is identity" do
      v = {1.0, 2.0, 3.0}
      assert Vector.negate(Vector.negate(v)) == v
    end
  end
end
