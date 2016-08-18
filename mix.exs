defmodule Mix.Tasks.Compile.Proj do
  def run(_) do
    0 = Mix.shell.cmd("make")
  end
end

defmodule Proj.Mixfile do
  use Mix.Project

  def project do
    [app: :proj,
     version: "0.2.0",
     elixir: "~> 1.0",
     compilers: [:proj, :elixir, :app],
     deps: deps,
     description: "Elixir coordinate conversion library using OSGeo's PROJ.4",
     name: "proj",
     package: package]
  end

  def application, do: []

  defp package do
    [maintainers: ["Candy Gumdrop"],
     licenses: ["CC0"],
     links: %{"GitHub" => "https://github.com/candygumdrop/proj",
              "Issues" => "https://github.com/candygumdrop/proj/issues"},
     files: ["src/*.c",
             "priv/.gitignore",
             "config",
             "lib",
             "mix.exs",
             "Makefile",
             "test",
             "COPYING",
             "README.md"]]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
