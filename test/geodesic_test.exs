defmodule GeodesicTest do
  use ExUnit.Case

  @wgs84_eq_radius 6378137
  @wgs84_flattening 1 / 298.257223563

  @buckingham_palace_lat 51.501476
  @buckingham_palace_lon -0.140634
  @eiffel_tower_lat 48.8584
  @eiffel_tower_lon 2.2945

  test "Proj.Geodesic.init/2 returns a %Proj.Geodesic{} struct" do
    geod = Proj.Geodesic.init(@wgs84_eq_radius, @wgs84_flattening)

    assert Map.get(geod, :__struct__) == Proj.Geodesic
    assert is_binary(Map.get(geod, :geod))
  end

  test "Proj.Geodesic.wgs84/0 has the correct parameters" do
    wgs84 = Proj.Geodesic.wgs84

    assert Map.get(wgs84, :__struct__) == Proj.Geodesic
    assert is_binary(Map.get(wgs84, :geod))

    {a, f} = Proj.Geodesic.params(wgs84)
    assert_in_delta(a, @wgs84_eq_radius, 0.000001)
    assert_in_delta(f, @wgs84_flattening, 0.000001)
  end

  test "Proj.Geodesic.direct/4 returns correct results" do
    wgs84 = Proj.Geodesic.wgs84
    coords = {@buckingham_palace_lat, @buckingham_palace_lon}

    {{lat, lng}, azimuth} = Proj.Geodesic.direct(wgs84, coords, 60, 100)

    assert_in_delta(lat, 51.50192539979596, 0.0000001)
    assert_in_delta(lng, -0.1393868003258145, 0.0000001)
    assert_in_delta(azimuth, 60.00097609168357, 0.0000001)
  end

  test "Proj.Geodesic.inverse/3 returns correct results" do
    wgs84 = Proj.Geodesic.wgs84
    coords_a = {@buckingham_palace_lat, @buckingham_palace_lon}
    coords_b = {@eiffel_tower_lat, @eiffel_tower_lon}

    {distance, azimuth_a, azimuth_b} =
      Proj.Geodesic.inverse(wgs84, coords_a, coords_b)

    assert_in_delta(distance, 341549.6819692767, 0.0000001)
    assert_in_delta(azimuth_a, 148.44884919324866, 0.0000001)
    assert_in_delta(azimuth_b, 150.31979086555856, 0.0000001)
  end

  test "Proj.Geodesic.travel/3 returns correct results" do
    coords = {@buckingham_palace_lat, @buckingham_palace_lon}

    {lat, lng} = Proj.Geodesic.travel(coords, 60, 100)

    assert_in_delta(lat, 51.50192539979596, 0.0000001)
    assert_in_delta(lng, -0.1393868003258145, 0.0000001)
  end

  test "Proj.Geodesic.distance/2 returns correct results" do
    coords_a = {@buckingham_palace_lat, @buckingham_palace_lon}
    coords_b = {@eiffel_tower_lat, @eiffel_tower_lon}

    distance = Proj.Geodesic.distance(coords_a, coords_b)

    assert_in_delta(distance, 341549.6819692767, 0.0000001)
  end

  test "Proj.Geodesic.params/0 returns correct values" do
    geod = Proj.Geodesic.init(@wgs84_eq_radius, @wgs84_flattening)

    {a, f} = Proj.Geodesic.params(geod)
    assert_in_delta(a, @wgs84_eq_radius, 0.000001)
    assert_in_delta(f, @wgs84_flattening, 0.000001)
  end
end
