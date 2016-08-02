defmodule Proj do
  @moduledoc """
  Provides functions to transform coordinates between given coordinate systems.

      iex> wgs84 = Proj.from_def("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
      #Proj<>
      iex> os_national_grid = Proj.from_def("+proj=tmerc +lat_0=49 +lon_0=-2 " <>
      ...>                                  "+k=0.9996012717 +x_0=400000 +y_0=-100000 " <>
      ...>                                  "+ellps=airy +datum=OSGB36 +units=m +no_defs")
      #Proj<>
      iex> Proj.transform({-0.140634, 51.501476, 0}, wgs84, os_national_grid)
      {529155, 179699, 0}
  """

  defstruct [:pj]

  @on_load :load

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
end
