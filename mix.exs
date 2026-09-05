defmodule AstroUtils.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jakedjohnson/astro_utils"

  def project do
    [
      app: :astro_utils,
      version: @version,
      elixir: "~> 1.17",
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Spherical geometry, vector/matrix math, circular statistics, Kepler mechanics, and time-scale helpers for Elixir."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md", "CONTRIBUTING.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "CONTRIBUTING.md", "LICENSE"],
      groups_for_modules: [
        Geometry: [
          AstroUtils.Angle,
          AstroUtils.Vector,
          AstroUtils.Matrix3,
          AstroUtils.Coordinates
        ],
        Mechanics: [AstroUtils.Kepler, AstroUtils.Time],
        Statistics: [AstroUtils.CircularStats],
        Utilities: [AstroUtils.Math]
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
