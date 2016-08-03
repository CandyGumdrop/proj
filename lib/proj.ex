defmodule Proj do
  @moduledoc """
  Provides functions to transform coordinates between given coordinate systems.

      iex> {:ok, wgs84} = Proj.from_def("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
      #Proj<>
      iex> {:ok, os_national_grid} = Proj.from_def("+proj=tmerc +lat_0=49 +lon_0=-2 " <>
      ...>                                         "+k=0.9996012717 +x_0=400000 +y_0=-100000 " <>
      ...>                                         "+ellps=airy +datum=OSGB36 +units=m +no_defs")
      #Proj<>
      iex> Proj.transform({-0.140634, 51.501476, 0}, wgs84, os_national_grid)
      {529155, 179699, 0}
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

  def from_def(_def) do
    raise "NIF not loaded"
  end

  def transform({_, _, _}, _from_proj, _to_proj) do
    raise "NIF not loaded"
  end

  def get_def(_proj) do
    raise "NIF not loaded"
  end

  def wgs84 do
    raise "NIF not loaded"
  end

  def to_deg({lon, lat, z}) do
    {lon * @rad_deg, lat * @rad_deg, z}
  end

  def to_rad({lon, lat, z}) do
    {lon * @deg_rad, lat * @deg_rad, z}
  end

  def from_known_def(file, name) do
    from_def("+init=#{file}:#{name}")
  end

  def from_epsg(name) do
    from_known_def("epsg", name)
  end

  def to_lat_lng!({x, y}, proj) do
    case transform({x, y, 0}, proj, wgs84) do
      {:ok, coords} ->
        {lng, lat, _z} = to_deg(coords)
        {lat, lng}
      {:error, error} ->
        raise error
    end
  end

  def from_lat_lng!({lat, lng}, proj) do
    case transform(to_rad({lng, lat, 0}), wgs84, proj) do
      {:ok, {x, y, _z}} ->
        {x, y}
      {:error, error} ->
        raise error
    end
  end
end
