defmodule AstroUtils.CircularStats do
  @moduledoc """
  Circular mean and minimal covering arc for sets of angles on a circle.

  Ordinary averaging breaks down on a circle: the arithmetic mean of 350° and
  10° is 180°, the exact opposite of the answer you want. These functions work
  on the circle, so the same pair averages to 0°.

  Inputs are degrees and need not be normalized; each function normalizes to
  `[0, 360)` internally. Both functions require a non-empty list and raise
  `FunctionClauseError` otherwise. `circular_mean/1` returns `:undefined` for
  sample sets that have no mean direction.

      iex> AstroUtils.CircularStats.circular_mean([350.0, 10.0])
      0.0
  """

  alias AstroUtils.Angle

  @typedoc "An angle in degrees."
  @type degree :: float()

  @typedoc """
  A covering arc: `{:arc, extent_degrees, start_degrees}`.

  Sweeping `extent_degrees` from `start_degrees` in the direction of
  increasing longitude covers every input sample.
  """
  @type arc :: {:arc, degree(), degree()}

  @full 360.0
  @eps 1.0e-6
  @vector_eps 1.0e-12
  @pi :math.pi()

  # ── Circular Mean ──────────────────────────────────────────────────

  @doc """
  Mean direction of a list of angles, returned in `[0, 360)`.

  The mean is always the direction of the resultant vector `Σ(cos θ, sin θ)`,
  so samples are weighted by direction rather than by count. A lopsided set
  inside a half-circle such as `[0.0, 10.0, 170.0]` therefore means to about
  `19.15°`, not to the arithmetic `60.0`.

  Returns `:undefined` when the resultant vector vanishes and no mean
  direction exists — antipodal pairs such as `[90.0, 270.0]`, or evenly
  spread samples such as `[0.0, 120.0, 240.0]`. Callers must handle this
  case; it is deliberately not a number.

  Raises `FunctionClauseError` on an empty list.

  ## Examples

      iex> AstroUtils.CircularStats.circular_mean([350.0, 10.0])
      0.0

      iex> AstroUtils.CircularStats.circular_mean([0.0, 10.0, 170.0]) |> Float.round(4)
      19.1519

      iex> AstroUtils.CircularStats.circular_mean([90.0, 270.0])
      :undefined
  """
  @spec circular_mean([degree()]) :: degree() | :undefined
  def circular_mean([_ | _] = degrees) do
    do_circular_mean(degrees, @full, &Angle.normalize_360/1)
  end

  # ── Minimal Covering Arc ───────────────────────────────────────────

  @doc """
  Shortest arc that contains every sample.

  Found by locating the largest empty gap between consecutive samples around
  the circle; the covering arc is the complement of that gap. Returns
  `{:arc, extent_degrees, start_degrees}`, where `start_degrees` is the sample
  just after the largest gap. If several gaps tie for largest, the smallest
  candidate start is used.

  A single sample, or repeats of one value, gives an arc of extent `0.0`.

  Raises `FunctionClauseError` on an empty list.

  ## Examples

      iex> AstroUtils.CircularStats.minimal_covering_arc([5.0, 15.0, 25.0])
      {:arc, 20.0, 5.0}

      iex> AstroUtils.CircularStats.minimal_covering_arc([350.0, 10.0, 20.0])
      {:arc, 30.0, 350.0}

      iex> AstroUtils.CircularStats.minimal_covering_arc([180.0])
      {:arc, 0.0, 180.0}
  """
  @spec minimal_covering_arc([degree()]) :: arc()
  def minimal_covering_arc([_ | _] = degrees) do
    compute_minimal_covering_arc(degrees, @full, &Angle.normalize_360/1)
  end

  # ── Internals ──────────────────────────────────────────────────────

  defp do_circular_mean(degrees, period, normalize_fn) do
    normalized = Enum.map(degrees, normalize_fn)
    resultant = vector_sum(normalized, period)

    # Mean resultant length, so the degeneracy test is independent of sample count.
    if vector_strength(resultant) / length(normalized) < @vector_eps do
      :undefined
    else
      result = vector_angle(resultant) * period / (2.0 * @pi)
      if abs(result - period) < @eps, do: 0.0, else: result
    end
  end

  defp compute_minimal_covering_arc(degrees, range_size, normalize_fn) do
    sorted = degrees |> Enum.map(normalize_fn) |> Enum.sort()
    count = length(sorted)

    cond do
      count == 1 ->
        {:arc, 0.0, hd(sorted)}

      sorted |> Enum.uniq() |> length() == 1 ->
        {:arc, 0.0, hd(sorted)}

      true ->
        gaps = covering_gaps(sorted, count, range_size, normalize_fn)
        largest_gap = gaps |> Enum.max_by(&elem(&1, 0)) |> elem(0)

        start =
          gaps
          |> Enum.filter(fn {g, _} -> g == largest_gap end)
          |> Enum.map(fn {_, idx} -> Enum.at(sorted, rem(idx + 1, count)) end)
          |> Enum.min()

        {:arc, range_size - largest_gap, start}
    end
  end

  defp covering_gaps(sorted, count, range_size, normalize_fn) do
    for i <- 0..(count - 1) do
      current = Enum.at(sorted, i)
      next = Enum.at(sorted, rem(i + 1, count))

      raw =
        if i == count - 1,
          do: next + range_size - current,
          else: next - current

      {normalize_fn.(raw), i}
    end
  end

  defp vector_sum(degrees, period) do
    Enum.reduce(degrees, {0.0, 0.0}, fn d, {xs, ys} ->
      r = d * 2.0 * @pi / period
      {xs + :math.cos(r), ys + :math.sin(r)}
    end)
  end

  defp vector_strength({x, y}), do: :math.sqrt(x * x + y * y)

  defp vector_angle({x, y}) do
    r = :math.atan2(y, x)
    if r < 0.0, do: r + 2.0 * @pi, else: r
  end
end
