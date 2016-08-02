defmodule Mix.Tasks.Compile.Proj do
  def run(_) do
    0 = Mix.shell.cmd("make proj_nif.so")
  end
end

defmodule Proj.Mixfile do
  use Mix.Project

  def project do
    [app: :proj,
     version: "0.1.0",
     elixir: "~> 1.0",
     compilers: [:proj, :elixir, :app],
     deps: deps,
     description: "Elixir coordinate conversion library using OSGeo's PROJ.4",
     name: "proj"]
  end

  def application, do: []

  defp deps do
    []
  end
end
