### A Pluto.jl notebook ###
# v0.14.2

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 52fdea4c-dfb2-4a60-a54d-1d31d0e5b32e
using Random: MersenneTwister

# ╔═╡ ad3e186e-f5c8-49a3-a1d8-32f7c6d34e3c
preamble = begin
	using DataFrames: DataFrame
	using VegaLite: Vega, VegaLite, @vlplot
	import PlutoUI
	import JSON
	import HypertextLiteral: @htl
	import CSV
end;

# ╔═╡ 3ab521b5-ca30-4bd6-8a2a-93c55e91eac9
slide_width = 1400;

# ╔═╡ 02c5877a-2ace-45d9-b114-7c6603d887cc
canvas = @vlplot(width = slide_width);

# ╔═╡ 6471a65a-0ec1-441f-82eb-b0303cc0a799
@htl("""
<style>
main {
	max-width: $(slide_width)px;
}
</style>
""")

# ╔═╡ 94918d60-37e7-48c8-8d08-28ad3e113960
function json_string(object)
	io = IOBuffer()
	JSON.print(io, object, 4)
	take!(io) |> String
end;

# ╔═╡ 4f89263e-ead3-4eaf-9e1f-8c3b52dbae09
html"<button onclick='present()'>present</button>"


# ╔═╡ 5abb7c5a-6270-4190-8172-3dbe69980e50
md"""
# A Brief Introduction to Vega Lite

**Lasse Peters, 2021-04-21**
"""

# ╔═╡ 5158be6f-f83c-4805-863d-e835e0ca5a5d
md"""
# What is Vega Lite?

- Vega-Lite is a JSON *specification* (VLSpec) for mapping data to visualizations
- Various methods for generating VLSpecs
  - Manually: VegaEditor
  - GUIs: DataVoyager, VegaDesktop
  - Programatically:
    - JavaScript: `vega-lite.js`
    - Julia: `VegaLite.jl`
    - Python: `Altair`
- The Vega-Lite compiler renders spec files to various output formats
  - `PNG`, `SVG`, `HTML`, ...
"""

# ╔═╡ f1e8583e-e995-4e55-aeb2-db0a31cfa9a9
md"""
# Grammar of Graphics -- TL;DR

Vega-Lite provides a very principled way of describing visualizations by following Leland Wilkinson's *Grammar of Graphics*:

- **Data** is given in a tabular format.

- **Encodings** map data fields to visual channels.

- **Channels** correspond to graphical properties.
  - e.g. `x`, `y`, `color`, `opacity`

- **Marks** derive their visual properties from these channels.
  - e.g. `point`, `line`, `area`
"""

# ╔═╡ c3015a6f-a4e5-431d-b010-0ff4dd0a8431
md"""
# Input Format: Tidy Data
"""

# ╔═╡ 51a6c6eb-bb4b-4301-ba37-df802f7878d0
md"""
**Tidy Data**: Table-like data that can be iterated column-wise
- Programmatically: `DataFrame`, iterable of `NamedTuple` or `Dict`.
- Standalone: YAML, CSV, JSON
"""

# ╔═╡ eccd1545-1eef-4e57-96c6-fde5090184ab
md"# A Simple Visualization Specification"

# ╔═╡ 23aa0896-a83c-4acb-b006-655c1d2e4f63
md"**Create a visualization specification**"

# ╔═╡ c276c185-2442-43e2-a9c8-eba347f26715
scatter_plot_spec = let
	@vlplot(
		mark = {"point", filled = true, opacity = 0.5},
		encoding = {
			x = "time",
			y = "amplitude",
		},
	)
end;

# ╔═╡ 1a9ce711-a086-444f-b88b-86fcc3509e7f
md"Noise σ: $(@bind σ PlutoUI.Slider(0.0:0.01:1.0; default=0.5, show_value = true))"

# ╔═╡ 61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
data = ((time, amplitude = sin(time) + σ * randn()) for time in 0:0.01:2π) |> DataFrame

# ╔═╡ 77048a1e-3761-4d34-95cb-a21f253b22a5
canvas + scatter_plot_spec(data)

# ╔═╡ 1562b780-2618-4eff-a582-cf6c1ffbae9b
md"""
# Tranformations and Layers
"""

# ╔═╡ 313934df-66a9-42e9-a6d4-73f13a6c90f6
md"Rolling window size: $(@bind window_size PlutoUI.Slider(2:2:40; show_value=true, default = 20))"

# ╔═╡ 0a7dae00-2154-42c9-9c39-ea16aa875013
statistics_plot_spec = let
@vlplot(transform = [
		{
			window = [
				{field = "amplitude", op = "mean", as = "rolling_average"},
				{field = "amplitude", op = "ci0", as = "rolling_lower"},
				{field = "amplitude", op = "ci1", as = "rolling_upper"},
			],
			frame = [-window_size/2, window_size/2]
		}
	]) +
	@vlplot(mark = "line", x = "time:q", y = "rolling_average:q") +
	@vlplot(mark = "errorband", x = "time:q", y = "rolling_lower:q", y2 = "rolling_upper:q")
end;

# ╔═╡ a6cbd17a-3656-4ce8-8728-e68b97c91695
data |> (canvas + scatter_plot_spec + statistics_plot_spec)

# ╔═╡ 9df0b338-8b0c-433d-bc18-1c251c22a5e3
md"# TODO: Saving VLSpecs"

# ╔═╡ b3d5f835-bd55-47b2-b3f5-b3ee2022b904
VegaLite.save("scatter_plot.vegalite", scatter_plot_spec);

# ╔═╡ 317d9a3e-03fe-4fac-95d3-6231516c0221
CSV.write("data.csv", data);

# ╔═╡ 9df59c02-8aba-4d15-8064-33763cfdb524
md"**VLSpec in JSON Format**"

# ╔═╡ 23cdd13b-4834-4fbe-9a18-b7ccec9717be
Text(json_string(scatter_plot_spec))

# ╔═╡ 669e6c2d-ad38-4ae1-955b-85454e158877
md"# Loading a VLSpec"

# ╔═╡ 9df46c9d-3169-4db2-9775-914b1772d3fe
loaded_spec = VegaLite.load("scatter_plot.vegalite");

# ╔═╡ 1a89e935-4d64-4291-bb78-4bb125963ce7
loaded_data = CSV.read("data.csv", DataFrame)

# ╔═╡ 34514626-c7c1-4929-84bb-e92b8c352ecb
canvas + loaded_spec(loaded_data)

# ╔═╡ fdb12d82-247b-44f9-8c9d-121543680086
md"# A Potential Research Workflow"

# ╔═╡ 458377ed-36db-4244-883c-19b07917a477
md"""
- **Code repos**: Create figures programatically with front-end of choice
- **Paper repo**: Include visualization pipeline as `.csv` + `.vl.json`
- **Other works**: Can load `.csv` and modify `.vegalite` to streamline figures per manuscript
"""

# ╔═╡ 29222cbd-71fe-4a26-a9cd-617fc749f058
md"""
# Final Remarks

##### Further Resources

- [example gallerie](https://vega.github.io/vega-lite/examples/)
- [online editor](https://vega.github.io/editor/#/examples/)
- [data voyager](https://vega.github.io/voyager2/)
"""

# ╔═╡ 16c4c54e-89de-4609-a707-907971c9c29a
md"# The End"

# ╔═╡ Cell order:
# ╟─52fdea4c-dfb2-4a60-a54d-1d31d0e5b32e
# ╠═ad3e186e-f5c8-49a3-a1d8-32f7c6d34e3c
# ╠═3ab521b5-ca30-4bd6-8a2a-93c55e91eac9
# ╠═02c5877a-2ace-45d9-b114-7c6603d887cc
# ╠═6471a65a-0ec1-441f-82eb-b0303cc0a799
# ╟─94918d60-37e7-48c8-8d08-28ad3e113960
# ╟─4f89263e-ead3-4eaf-9e1f-8c3b52dbae09
# ╟─5abb7c5a-6270-4190-8172-3dbe69980e50
# ╟─5158be6f-f83c-4805-863d-e835e0ca5a5d
# ╟─f1e8583e-e995-4e55-aeb2-db0a31cfa9a9
# ╟─c3015a6f-a4e5-431d-b010-0ff4dd0a8431
# ╟─51a6c6eb-bb4b-4301-ba37-df802f7878d0
# ╠═61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
# ╟─eccd1545-1eef-4e57-96c6-fde5090184ab
# ╟─23aa0896-a83c-4acb-b006-655c1d2e4f63
# ╠═c276c185-2442-43e2-a9c8-eba347f26715
# ╠═77048a1e-3761-4d34-95cb-a21f253b22a5
# ╟─1a9ce711-a086-444f-b88b-86fcc3509e7f
# ╟─1562b780-2618-4eff-a582-cf6c1ffbae9b
# ╠═0a7dae00-2154-42c9-9c39-ea16aa875013
# ╠═a6cbd17a-3656-4ce8-8728-e68b97c91695
# ╟─313934df-66a9-42e9-a6d4-73f13a6c90f6
# ╟─9df0b338-8b0c-433d-bc18-1c251c22a5e3
# ╠═b3d5f835-bd55-47b2-b3f5-b3ee2022b904
# ╠═317d9a3e-03fe-4fac-95d3-6231516c0221
# ╟─9df59c02-8aba-4d15-8064-33763cfdb524
# ╟─23cdd13b-4834-4fbe-9a18-b7ccec9717be
# ╟─669e6c2d-ad38-4ae1-955b-85454e158877
# ╠═9df46c9d-3169-4db2-9775-914b1772d3fe
# ╠═1a89e935-4d64-4291-bb78-4bb125963ce7
# ╠═34514626-c7c1-4929-84bb-e92b8c352ecb
# ╟─fdb12d82-247b-44f9-8c9d-121543680086
# ╟─458377ed-36db-4244-883c-19b07917a477
# ╟─29222cbd-71fe-4a26-a9cd-617fc749f058
# ╟─16c4c54e-89de-4609-a707-907971c9c29a
