defmodule AstroUtils.CircularStatsTest do
  use ExUnit.Case, async: true

  alias AstroUtils.Angle
  alias AstroUtils.CircularStats

  doctest AstroUtils.CircularStats

  @eps 1.0e-6

  describe "circular_mean/1" do
    test "simple cases" do
      assert_in_delta CircularStats.circular_mean([5.0, 15.0, 25.0]), 15.0, @eps
      assert_in_delta CircularStats.circular_mean([0.0]), 0.0, @eps
      assert_in_delta CircularStats.circular_mean([180.0]), 180.0, @eps
      assert_in_delta CircularStats.circular_mean([90.0, 90.0, 90.0]), 90.0, @eps
    end

    test "wrap-around" do
      assert_in_delta CircularStats.circular_mean([350.0, 10.0]), 0.0, @eps
      assert_in_delta CircularStats.circular_mean([350.0, 0.0, 10.0]), 0.0, @eps
    end

    test "uses the resultant vector even when samples span less than 180 degrees" do
      assert_in_delta CircularStats.circular_mean([0.0, 10.0, 170.0]), 19.1519278881, @eps
      assert_in_delta CircularStats.circular_mean([0.0, 10.0, 179.0]), 10.9800294841, @eps
    end

    test "is stable across the 180 degree span boundary" do
      just_under = CircularStats.circular_mean([0.0, 10.0, 179.0])
      just_over = CircularStats.circular_mean([0.0, 10.0, 181.0])

      assert_in_delta just_under, just_over, 2.5
    end

    test "degenerate sample sets have no mean direction" do
      assert CircularStats.circular_mean([0.0, 180.0]) == :undefined
      assert CircularStats.circular_mean([90.0, 270.0]) == :undefined
      assert CircularStats.circular_mean([0.0, 120.0, 240.0]) == :undefined
      assert CircularStats.circular_mean([0.0, 90.0, 180.0, 270.0]) == :undefined
    end

    test "mean is inside minimal covering arc" do
      for points <- [[5.0, 15.0, 25.0], [350.0, 10.0], [90.0, 90.0, 90.0], [0.0, 10.0, 170.0]] do
        mean = CircularStats.circular_mean(points)
        {:arc, span, start} = CircularStats.minimal_covering_arc(points)
        end_deg = Angle.normalize_360(start + span)

        inside =
          if start <= end_deg,
            do: mean >= start - @eps and mean <= end_deg + @eps,
            else: mean >= start - @eps or mean <= end_deg + @eps

        assert inside, "Mean #{mean} not in arc: start=#{start}, span=#{span}"
      end
    end
  end

  describe "minimal_covering_arc/1" do
    test "simple sequences" do
      {:arc, span, start} = CircularStats.minimal_covering_arc([5.0, 15.0, 25.0])
      assert_in_delta span, 20.0, @eps
      assert_in_delta start, 5.0, @eps
    end

    test "wrap-around" do
      {:arc, span, start} = CircularStats.minimal_covering_arc([350.0, 10.0])
      assert_in_delta span, 20.0, @eps
      assert_in_delta start, 350.0, @eps
    end

    test "single point" do
      {:arc, span, start} = CircularStats.minimal_covering_arc([180.0])
      assert_in_delta span, 0.0, @eps
      assert_in_delta start, 180.0, @eps
    end

    test "repeated point" do
      {:arc, span, start} = CircularStats.minimal_covering_arc([90.0, 90.0, 90.0])
      assert_in_delta span, 0.0, @eps
      assert_in_delta start, 90.0, @eps
    end

    test "unnormalized inputs" do
      {:arc, span, start} = CircularStats.minimal_covering_arc([-10.0, 370.0, 725.0])
      assert_in_delta span, 20.0, @eps
      assert_in_delta start, 350.0, @eps
    end

    test "arc contains all points" do
      for points <- [[5.0, 15.0, 25.0], [350.0, 10.0, 20.0], [-10.0, 370.0, 725.0]] do
        {:arc, span, start} = CircularStats.minimal_covering_arc(points)

        Enum.each(points, fn point ->
          normalized = Angle.normalize_360(point)
          end_deg = Angle.normalize_360(start + span)

          inside =
            if start <= end_deg,
              do: normalized >= start - 1.0e-9 and normalized <= end_deg + 1.0e-9,
              else: normalized >= start - 1.0e-9 or normalized <= end_deg + 1.0e-9

          assert inside, "Point #{point} not in arc"
        end)
      end
    end
  end
end
