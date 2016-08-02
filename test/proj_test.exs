defmodule ProjTest do
  use ExUnit.Case

  @wgs84_def "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  @epsg_27700_def "+proj=tmerc +lat_0=49 +lon_0=-2 " <>
                  "+k=0.9996012717 +x_0=400000 +y_0=-100000 " <>
                  "+ellps=airy +datum=OSGB36 +units=m +no_defs"

  test "Proj.from_def/1 returns a %Proj{} struct" do
    proj = Proj.from_def(@wgs84_def)
    assert Map.get(proj, :__struct__) == Proj
    assert is_binary(Map.get(proj, :pj))
  end

  test "Proj.transform/3 returns a 3-tuple of coordinates" do
    wgs84 = Proj.from_def(@wgs84_def)
    epsg_27700 = Proj.from_def(@epsg_27700_def)
    result = Proj.transform({-0.140634, 51.501476, 0}, wgs84, epsg_27700)
    assert tuple_size(result) == 3
  end
end
