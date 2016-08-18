defmodule Proj.Geodesic do
  @moduledoc """
  Provides functions to solve problems involving geodesic lines.

  Common problems this can solve:

  - Finding the distance between two locations

  - Finding the bearings between two locations

  - Finding the resulting location after moving `x` metres forwards facing a
    certain bearing from a given location

  - Plotting a set of points in a line between two locations
  """

  @on_load :load

  defstruct [:geod, :a, :f]

  defimpl Inspect, for: Proj.Geodesic do
    def inspect(geod, _opts) do
      {a, f} = Proj.Geodesic.params(geod)
      "#Proj.Geodesic<#{a}, #{f}>"
    end
  end

  def load do
    filename = :filename.join(:code.priv_dir(:proj), 'geodesic_nif')
    :ok = :erlang.load_nif(filename, 0)
  end

  @doc """
  Creates a new `Proj.Geodesic` specification for the planet's ellipsoid
  parameters, where `a` represents the equatorial radius in metres, and `f`
  represents the flattening.

      iex> Proj.Geodesic.init(6378137, 1 / 298.257223563)
      #Proj.Geodesic<6378137.0, 0.0033528106647474805>
  """
  def init(_a, _f) do
    raise "NIF not loaded"
  end

  @doc """
  Returns a `Proj.Geodesic` specification for the Earth's ellipsoid parameters
  as specified by WGS84.
  """
  def wgs84 do
    raise "NIF not loaded"
  end

  @doc """
  Calculates the resultant coordinates and bearing after travelling a given
  distance forwards along a geodesic line through a given starting point and
  azimuth (bearing).

  Return value is in the format `{{lat, lng}, bearing}`.

  All coordinates and bearings are given in degrees.  `distance` is in metres.

      iex> wgs84 = Proj.Geodesic.wgs84
      iex> Proj.Geodesic.direct(wgs84, {51.501476, -0.140634}, 60, 100)
      {{51.50192539979596, -0.1393868003258145}, 60.00097609168357}
  """
  def direct(_geod, _coords, _azimuth, _distance) do
    raise "NIF not loaded"
  end

  @doc """
  Calculates the length of the geodesic line between two points and the bearing
  of the line at each point.

  Return value is in the format `{distance, bearing_a, bearing_b}`.

  All coordinates and bearings are given in degrees.  `distance` is in metres.

      iex> wgs84 = Proj.Geodesic.wgs84
      iex> Proj.Geodesic.inverse(wgs84, {51.501476, -0.140634}, {48.8584, 2.2945})
      {341549.6819692767, 148.44884919324866, 150.31979086555856}
  """
  def inverse(_geod, _coords_a, _coords_b) do
    raise "NIF not loaded"
  end

  @doc """
  Calculates the resulting position after travelling `distance` metres forwards
  from `coords` facing a bearing of `azimuth`.

  This is a convenience wrapper around `Proj.Geodesic.direct/4` which uses the
  WGS84 ellipsoid and only returns the resulting coordinates.

  Return value is in the format `{lat, lng}`.

  All coordinates and bearings are given in degrees.

      iex> Proj.Geodesic.travel({51.501476, -0.140634}, 60, 100)
      {51.50192539979596, -0.1393868003258145}
  """
  def travel(coords, azimuth, distance) do
    {result_coords, _azimuth} = direct(wgs84, coords, azimuth, distance)
    result_coords
  end

  @doc """
  Calculates the distance in metres between two points.

  This is a convenience wrapper around `Proj.Geodesic.inverse/3` which uses the
  WGS84 ellipsoid and only returns the resulting distance.

  All coordinates are given in degrees.

      iex> Proj.Geodesic.distance({51.501476, -0.140634}, {48.8584, 2.2945})
      341549.6819692767
  """
  def distance(coords_a, coords_b) do
    {result_distance, _azimuth_a, _azimuth_b} = inverse(wgs84, coords_a, coords_b)
    result_distance
  end

  @doc """
  Gets the equatorial radius in metres and flattening of a given `Proj.Geodesic`
  ellipsoid specification.

  Return value is in the format `{equatorial_radius, flattening}`

      iex> wgs84 = Proj.Geodesic.wgs84
      iex> Proj.Geodesic.params(wgs84)
      {6378137.0, 0.0033528106647474805}
  """
  def params(geod) do
    {geod.a, geod.f}
  end
end
