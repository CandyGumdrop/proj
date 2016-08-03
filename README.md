# Proj

Proj is an Elixir library for converting coordinates between different
coordinate systems, using Erlang NIFs to the OSGeo PROJ.4 library.

## Installation

Before you can install Proj, you must have:

- gcc
- PROJ.4 newer than 4.8.0

## Example Usage

```elixir
iex> {:ok, bng} = Proj.from_epsg(27700) # British National Grid CRS is EPSG:27700
{:ok, #Proj<+init=epsg:27700 ...>}
iex> Proj.to_lat_lng!({529155, 179699}, bng)
{51.50147938477216, -0.1406319210455952}
```
