defmodule Honeybee.MixProject do
  use Mix.Project

  def project do
    [
      app: :honeybee,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Test, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7.1"},
      {:dialyxir, "~> 0.4", only: :dev},
      {:ex_doc, "~> 0.19.3", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Simon Finnman"],
      licenses: ["GNU"],
      links: %{github: "https://github.com/sfinnman/honeybee"},
      files: ~w(lib mix.exs README.md .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "introduction",
      extra_section: "GUIDES",
      formatters: ["html"],
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp extras do
    [
      "guides/honeybee/introduction.md",
      "guides/honeybee/routing.md"
    ]
  end

  defp groups_for_extras do
    [
      Honeybee: ~r/guides\/honeybee\/.?/
    ]
  end

  defp groups_for_modules do
    []
  end
end
