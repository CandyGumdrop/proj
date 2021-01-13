defmodule ProjTest do
  use ExUnit.Case

  @wgs84_def "+init=epsg:4326"
  @epsg_27700_def "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.06,0.15,0.247,0.842,-20.489 +units=m +no_defs"

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

  test "Proj.get_def/1 returns a string" do
    {:ok, wgs84} = Proj.from_def(@wgs84_def)

    assert is_binary(Proj.get_def(wgs84))
  end

  test "Proj.wgs84 returns a Proj struct" do
    proj = Proj.wgs84

    assert Map.get(proj, :__struct__) == Proj
  end

  test "Proj.to_deg/1 returns correct values" do
    coords_rad = {@buckingham_palace_lon_rad,
                  @buckingham_palace_lat_rad, 123}

    {lon, lat, z} = Proj.to_deg(coords_rad)

    assert round(lon * 1000) == round(@buckingham_palace_lon * 1000)
    assert round(lat * 1000) == round(@buckingham_palace_lat * 1000)
    assert z == 123
  end

  test "Proj.to_rad/1 returns correct values" do
    coords_deg = {@buckingham_palace_lon,
                  @buckingham_palace_lat, 123}

    {lon, lat, z} = Proj.to_rad(coords_deg)

    assert round(lon * 100000) == round(@buckingham_palace_lon_rad * 100000)
    assert round(lat * 100000) == round(@buckingham_palace_lat_rad * 100000)
    assert z == 123
  end

  test "Proj.from_known_def/2 returns a Proj struct" do
    {:ok, proj} = Proj.from_known_def("world", "bng")

    assert Map.get(proj, :__struct__) == Proj
  end

  test "Proj.from_epsg/1 returns a Proj struct" do
    {:ok, proj} = Proj.from_epsg(27700)

    assert Map.get(proj, :__struct__) == Proj
  end

  test "Proj.to_lat_lng!/2 returns correct values" do
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)

    {lat, lon} = Proj.to_lat_lng!({@buckingham_palace_easting,
                                   @buckingham_palace_northing},
                                  epsg_27700)

    assert round(lat * 1000) == round(@buckingham_palace_lat * 1000)
    assert round(lon * 1000) == round(@buckingham_palace_lon * 1000)
  end

  test "Proj.from_lat_lng!/2 returns correct values" do
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)

    {easting, northing} = Proj.from_lat_lng!({@buckingham_palace_lat,
                                              @buckingham_palace_lon},
                                             epsg_27700)

    assert round(easting) == round(@buckingham_palace_easting)
    assert round(northing) == round(@buckingham_palace_northing)
  end
end
