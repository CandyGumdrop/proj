defmodule Proj do
  @moduledoc """
  Provides functions to transform coordinates between given coordinate systems.

      iex> {:ok, bng} = Proj.from_epsg(27700) # British National Grid CRS is EPSG:27700
      {:ok, #Proj<+init=epsg:27700 ...>}
      iex> Proj.to_lat_lng!({529155, 179699}, bng)
      {51.50147938477216, -0.1406319210455952}
  """

  @deg_rad :math.pi / 180
  @rad_deg 180 / :math.pi

  @on_load :load

  defstruct [:pj]

  defimpl Inspect, for: Proj do
    def inspect(proj, _opts) do
      "#Proj<#{String.trim(Proj.get_def(proj))}>"
    end
  end

  def load do
    filename = :filename.join(:code.priv_dir(:proj), 'proj_nif')
    :ok = :erlang.load_nif(filename, 0)
  end

  @doc """
  Returns a new Proj projection specification object for a given PROJ.4
  parameter list.

  Returns `{:ok, proj}` on success, or `{:error, "reason"}` if the PROJ.4
  parameter string is invalid.

  ## Examples

      Proj.from_def("+init=epsg:4326")

      Proj.from_def("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

      Proj.from_def("+init=world:bng")

      Proj.from_def("+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000
                     +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs")

  See https://trac.osgeo.org/proj/wiki/GenParms for documentation on how these
  parameter lists.

  One way of finding the the PROJ.4 parameter list you require is to search
  http://spatialreference.org/ for your desired CRS and find the PROJ.4
  parameter list under the "Proj4" link on a CRS's page.
  """
  def from_def(_def) do
    raise "NIF not loaded"
  end

  @doc """
  Transforms coordinates from one Proj CRS to another.

  Coordinates are given in the order `{x, y, z}`, or for geographic coordinates,
  `{longitude, latitude, z}`, where `z` is the altitude above the geoid of the
  CRS.  `longitude` and `latitude` must be given in radians.  `Proj.to_rad/1`
  may be helpful if you have coordinates in degrees.

  Returns `{:ok, {x, y, z}}` on success, or `{:error, "reason"}` if the PROJ.4
  library was unable to perform a transformation.  If geographic coordinates are
  returned, they will be in the order `{longitude, latitude, z}`, and will be in
  radians.
  """
  def transform({_, _, _}, _from_proj, _to_proj) do
    raise "NIF not loaded"
  end

  @doc """
  Returns the `def` string given to create the given Proj object, expanded to
  its fullest form if possible.

      iex> Proj.get_def(Proj.wgs84)
      " +init=epsg:4326 +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  """
  def get_def(_proj) do
    raise "NIF not loaded"
  end

  @doc """
  Returns a Proj object for the WGS84 geographic coordinate reference system.

  WGS84 is the standard coordinate system used for GPS and is most likely what
  you need when working with `{latitude, longitude}` coordinates.
  """
  def wgs84 do
    raise "NIF not loaded"
  end

  @doc """
  Turns a `{longitude_radians, latitude_radians, z}` tuple into
  `{longitude_degrees, latitude_degrees, z}`.
  """
  def to_deg({lon, lat, z}) do
    {lon * @rad_deg, lat * @rad_deg, z}
  end

  @doc """
  Turns a `{longitude_degrees, latitude_degrees, z}` tuple into
  `{longitude_radians, latitude_radians, z}`.
  """
  def to_rad({lon, lat, z}) do
    {lon * @deg_rad, lat * @deg_rad, z}
  end

  @doc """
  Returns a Proj object for a given known PROJ.4 init file definition.

  Returns `{:ok, proj}` on success, or `{:error, "reason"}` if the definition is
  not found.

  On Linux, by default, these definitions should be stored in `/usr/share/proj/`
  with your PROJ.4 installation.

      Proj.from_known_def("epsg", "4326") # WGS84
      Proj.from_known_def("world", "bng") # British National Grid
  """
  def from_known_def(file, name) do
    from_def("+init=#{file}:#{name}")
  end

  @doc """
  Returns a Proj object for a given EPSG code from the EPSG Geodetic Parameter
  Dataset.

  Returns `{:ok, proj}` on success, or `{:error, "reason"}` if the EPSG
  definition is not found.

      Proj.from_epsg(4326) # WGS84
      Proj.from_epsg(27700) # British National Grid
  """
  def from_epsg(name) do
    from_known_def("epsg", name)
  end

  @doc """
  Converts a given `{easting, northing}` pair and its CRS `proj` to a WGS84
  `{latitude, longitude}` pair, where `latitude` and `longitude` are in degrees.

  This function raises on error, unlike `Proj.transform/3`.

  This is a convenience function for a common use case of Proj.

      iex> {:ok, bng} = Proj.from_epsg(27700)
      {:ok, #Proj<+init=epsg:27700 ...>}
      iex> Proj.to_lat_lng!({529155, 179699}, bng)
      {51.50147938477216, -0.1406319210455952}
  """
  def to_lat_lng!({x, y}, proj) do
    case transform({x, y, 0}, proj, wgs84()) do
      {:ok, coords} ->
        {lng, lat, _z} = to_deg(coords)
        {lat, lng}
      {:error, error} ->
        raise error
    end
  end

  @doc """
  Converts a given WGS84 `{latitude, longitude}` pair in degrees to the
  equivalent `{easting, northing}` in the CRS `proj`.

  This function raises on error, unlike `Proj.transform/3`.

  This is a convenience function for a common use case of Proj.

      iex> {:ok, bng} = Proj.from_epsg(27700)
      {:ok, #Proj<+init=epsg:27700 ...>}
      iex> Proj.from_lat_lng!({51.501479, -0.140631}, bng)
      {529155.0658918166, 179698.9583449281}
  """
  def from_lat_lng!({lat, lng}, proj) do
    case transform(to_rad({lng, lat, 0}), wgs84(), proj) do
      {:ok, {x, y, _z}} ->
        {x, y}
      {:error, error} ->
        raise error
    end
  end
end
