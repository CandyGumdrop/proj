defmodule ProjTest do
  use ExUnit.Case

  @wgs84_def "+init=epsg:4326"
  @epsg_27700_def "+init=epsg:27700"

  @deg_rad 0.0174532925

  @buckingham_palace_lon -0.140634
  @buckingham_palace_lat 51.501476

  @buckingham_palace_lon_rad @buckingham_palace_lon * @deg_rad
  @buckingham_palace_lat_rad @buckingham_palace_lat * @deg_rad

  test "Proj.from_def/1 returns a %Proj{} struct" do
    {:ok, proj} = Proj.from_def(@wgs84_def)

    assert Map.get(proj, :__struct__) == Proj
    assert is_binary(Map.get(proj, :pj))
  end

  test "Proj.transform/3 returns a 3-tuple of coordinates" do
    {:ok, wgs84} = Proj.from_def(@wgs84_def)
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)

    {:ok, result} = Proj.transform({@buckingham_palace_lon_rad,
                                    @buckingham_palace_lat_rad, 0},
                                   wgs84, epsg_27700)

    {x, y, z} = result

    assert is_float(x)
    assert is_float(y)
    assert is_float(z)
  end
end
