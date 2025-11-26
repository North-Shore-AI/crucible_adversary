defmodule CrucibleAdversary.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/North-Shore-AI/crucible_adversary"

  def project do
    [
      app: :crucible_adversary,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "CrucibleAdversary"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Adversarial testing and robustness framework for AI models with 25 attacks " <>
      "(character/word/semantic perturbations, prompt injection, jailbreak, " <>
      "extraction, inversion), defenses (detection/filtering/sanitization), " <>
      "certified robustness metrics, and attack composition."
  end

  defp package do
    [
      name: "crucible_adversary",
      description: description(),
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE docs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Online documentation" => "https://hexdocs.pm/crucible_adversary"
      },
      maintainers: ["nshkrdotcom"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "CrucibleAdversary",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "docs/20251020/FUTURE_VISION.md",
        "docs/20251125/ENHANCEMENTS_DESIGN.md"
      ],
      groups_for_extras: [
        "Release Notes": ["CHANGELOG.md"],
        Legal: ["LICENSE"],
        Roadmap: [
          "docs/20251020/FUTURE_VISION.md",
          "docs/20251125/ENHANCEMENTS_DESIGN.md"
        ]
      ],
      assets: %{"assets" => "assets"},
      logo: "assets/crucible_adversary.svg",
      before_closing_head_tag: &mermaid_config/1
    ]
  end

  defp mermaid_config(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp mermaid_config(_), do: ""
end
