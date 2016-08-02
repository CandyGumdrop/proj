defmodule ProjTest do
  use ExUnit.Case

  @wgs84_def "+init=epsg:4326"
  @epsg_27700_def "+init=epsg:27700"

  test "Proj.from_def/1 returns a %Proj{} struct" do
    {:ok, proj} = Proj.from_def(@wgs84_def)

    assert Map.get(proj, :__struct__) == Proj
    assert is_binary(Map.get(proj, :pj))
  end

  test "Proj.transform/3 returns a 3-tuple of coordinates" do
    {:ok, wgs84} = Proj.from_def(@wgs84_def)
    {:ok, epsg_27700} = Proj.from_def(@epsg_27700_def)

    result = Proj.transform({-0.140634, 51.501476, 0}, wgs84, epsg_27700)

    assert (case result do
              {x, y, z} when is_float(x)
                        and  is_float(y)
                        and  is_float(z) -> true
              _ -> false
            end), "Expected {float, float, float}"
  end
end
