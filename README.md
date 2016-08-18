# Proj

Proj is an Elixir library for converting coordinates between different
coordinate systems, using Erlang NIFs to the OSGeo PROJ.4 library.

Proj also supports geodesic functions from PROJ.4.  A geodesic is the shortest
line around the globe which crosses through two points.  This is useful for
solving problems such as:

- Finding the distance between two locations

- Finding the bearings between two locations

- Finding the resulting location after moving `x` metres forwards facing a
  certain bearing from a given location

- Plotting a set of points in a line between two locations

## Installation

Before you can install Proj, you must have:

- gcc
- PROJ.4 newer than 4.9.0

Proj has currently only been tested on GNU/Linux.  If you are unable to get it
running on Windows, Mac OS X or any other system, please make in issue on GitHub
and I will try to work with you to figure out what is necessary to get it
running on your platform.

## Example Usage

```elixir
iex> {:ok, bng} = Proj.from_epsg(27700) # British National Grid CRS is EPSG:27700
{:ok, #Proj<+init=epsg:27700 ...>}

# Convert the British National Grid Northing + Easting of Buckingham Palace into
# a Latitude + Longitude pair
iex> Proj.to_lat_lng!({529155, 179699}, bng)
{51.50147938477216, -0.1406319210455952}

# Convert the Latitude + Longitude of Buckingham Palace to its
# British National Grid Northing + Easting
iex> Proj.from_lat_lng!({51.501479, -0.140631}, bng)
{529155.0658918166, 179698.9583449281}

# Calculate the shortest distance "as the crow flies" in metres between
# Buckingham Palace and the Eiffel Tower
iex> Proj.Geodesic.distance({51.501476, -0.140634}, {48.8584, 2.2945})
341549.6819692767

# Calculate the resulting location after travelling 100 metres forwards from
# Buckingham Palace, facing a bearing of 060°
iex> Proj.Geodesic.travel({51.501476, -0.140634}, 60, 100)
{51.50192539979596, -0.1393868003258145}
```
