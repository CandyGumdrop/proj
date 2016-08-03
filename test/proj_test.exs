defmodule ProjTest do
  use ExUnit.Case

  @wgs84_def "+init=epsg:4326"
  @epsg_27700_def "+init=epsg:27700"

  @deg_rad 0.0174532925
  @rad_deg 1 / @deg_rad

  @buckingham_palace_lon -0.140634
  @buckingham_palace_lat 51.501476

  @buckingham_palace_lon_rad @buckingham_palace_lon * @deg_rad
  @buckingham_palace_lat_rad @buckingham_palace_lat * @deg_rad

  @buckingham_palace_easting 529154.8663
  @buckingham_palace_northing 179698.6129

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

  test "Proj.transform/3 returns correct results for WGS84 to BNG" do
    {:ok, wgs84} = Proj.from_def(@wgs84_def)
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)

    {:ok, result} = Proj.transform({@buckingham_palace_lon_rad,
                                    @buckingham_palace_lat_rad, 0},
                                   wgs84, epsg_27700)

    {x, y, z} = result

    assert round(x) == 529155
    assert round(y) == 179699
    assert round(z) == -46
  end

  test "Proj.transform/3 returns correct results for BNG to WGS84" do
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)
    {:ok, wgs84} = Proj.from_def(@wgs84_def)

    {:ok, result} = Proj.transform({@buckingham_palace_easting,
                                    @buckingham_palace_northing, 0},
                                   epsg_27700, wgs84)

    {x, y, _z} = result

    deg_x = x * @rad_deg
    deg_y = y * @rad_deg

    assert round(deg_x * 1000) == round(@buckingham_palace_lon * 1000)
    assert round(deg_y * 1000) == round(@buckingham_palace_lat * 1000)
  end
end
