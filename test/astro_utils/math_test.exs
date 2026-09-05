defmodule AstroUtils.MathTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Math

  doctest AstroUtils.Math

  describe "roundn/2" do
    test "rounds to n decimal places" do
      assert Math.roundn(1.23456, 2) == 1.23
      assert Math.roundn(1.23456, 4) == 1.2346
    end

    test "default precision is 4" do
      assert Math.roundn(1.23456) == 1.2346
    end

    test "rounds to 0 places" do
      assert Math.roundn(1.5, 0) == 2.0
    end
  end
end
