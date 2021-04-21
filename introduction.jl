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
begin
	import PlutoUI
	import FileIO
	import CSVFiles
	import JSON
	import HypertextLiteral: @htl
	import Random
	
	using DataFrames: DataFrame
	using VegaLite: Vega, VegaLite, @vlplot
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

- Vega-Lite provides a *specification* (VLSpec) for mapping data to visualizations
- Various methods for generating VLSpecs
  - Manually: VegaEditor
  - GUIs: DataVoyager, VegaDesktop
  - Programatically:
    - JavaScript: `vega-lite.js`
    - Julia: `VegaLite.jl`
    - Python: `Altair`
- The Vega-Lite compiler renders VLSpecs to various output formats
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

- **Marks** are visualization primitives that derive their visual properties from channels.
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
		  x = "time:q",
		  y = "amplitude:q",
		  color = "class:n"
		},
	)
end;

# ╔═╡ 9df59c02-8aba-4d15-8064-33763cfdb524
md"**Generated VLSpec** can be saved to disk along with data to make the figure reproducable:"

# ╔═╡ 23cdd13b-4834-4fbe-9a18-b7ccec9717be
Text(json_string(scatter_plot_spec))

# ╔═╡ 174bddf0-a4f1-4f90-a4fe-fe1ee801c842
md"# Rendering a VLSpec"

# ╔═╡ 1a9ce711-a086-444f-b88b-86fcc3509e7f
md"Noise σ: $(@bind σ PlutoUI.Slider(0.0:0.01:1.0; default=0.2, show_value = true))"

# ╔═╡ 61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
data = Iterators.flatten((
			((time, amplitude  = sin(time) + σ * randn(), class = "A", ) for time in 0:0.01:2π),
			((time, amplitude = cos(time) + σ * randn(), class = "B",) for time in 0:0.01:2π)
		)) |> DataFrame

# ╔═╡ 77048a1e-3761-4d34-95cb-a21f253b22a5
canvas + scatter_plot_spec(data)

# ╔═╡ 1562b780-2618-4eff-a582-cf6c1ffbae9b
md"""
# Adding Transformations
"""

# ╔═╡ 313934df-66a9-42e9-a6d4-73f13a6c90f6
md"Rolling window size: $(@bind window_size PlutoUI.Slider(2:2:40; show_value=true, default = 20))"

# ╔═╡ 0a7dae00-2154-42c9-9c39-ea16aa875013
statistics_plot_spec = let
	@vlplot(
		x = "time:q",
		color = "class:n",
		transform = [
			{
				window = [
					{field = "amplitude", op = "mean", as = "rolling_average"},
					{field = "amplitude", op = "ci0", as = "rolling_lower"},
					{field = "amplitude", op = "ci1", as = "rolling_upper"},
				],
				frame = [-window_size/2, window_size/2],
				groupby = ["class"]
			}
		],	
	) +
	@vlplot(mark = "line", encoding = {y = "rolling_average:q"}) +
	@vlplot(mark = "errorband", encoding = {y = "rolling_lower:q", y2 = "rolling_upper:q"})
end;

# ╔═╡ a6cbd17a-3656-4ce8-8728-e68b97c91695
data |> (canvas + scatter_plot_spec + statistics_plot_spec)

# ╔═╡ 5c09ced6-09b7-494d-a561-7484418fd08d
md"# Interaction: Tooltips and Parameters"

# ╔═╡ ecf745b5-f33e-4512-9d9b-9ec9bdf71687
md"""
**Tooltip** is also just a mark property that can be bound to a *channel*.
"""

# ╔═╡ 68946680-b280-40ee-96ed-4da9ed5dc529
tooltip_example_spec = let
	@vlplot(
		width = slide_width,
		mark = "point",
		encoding = {x = "time:q", y = "amplitude:q", tooltip = "class" }
	)
end;

# ╔═╡ 6a000db6-57dd-4f26-b162-30d996f437ae
data |> tooltip_example_spec |> FileIO.save("examples/tooltip_example.html")

# ╔═╡ 5caa8bc7-c3ea-43f5-abd5-6f1ce9b2b43a
tooltip_example_spec |> json_string |> Text;

# ╔═╡ d3934459-981f-42af-91c1-8000f221e43f
md"""
**Parameters** can be bound to input elements to interact with data.
"""

# ╔═╡ 581a5ad1-90ef-47d7-93e9-946bde1a0a86
parameter_example_spec = let
	@vlplot(
		width = slide_width,
		params = [{ name = "threshold", value = 7, bind = { input = "range", min = 0.1, max = 7, step = 0.1}}],
		transform = [{ filter = "datum.time < threshold"}],
	)
end;

# ╔═╡ a5e112e7-581c-4a87-8f7b-183baa4a4558
data |> (parameter_example_spec + scatter_plot_spec) |> FileIO.save("examples/parameter_example.html")

# ╔═╡ a6869f88-0d5a-41d2-9819-a189e37e282a
parameter_example_spec |> json_string |> Text;

# ╔═╡ 29222cbd-71fe-4a26-a9cd-617fc749f058
md"""
# Conclusion
"""

# ╔═╡ fd8f4530-8377-4cd0-8ba9-3d4c7619e04e
md"""
**A Potential Research Workflow**

- **Code repos**: Create figures programatically with front-end of choice
- **Paper repo**: Include visualization pipeline as `.csv` + `.vegalite`
- **Other works**: Can load `.csv` and modify `.vegalite` to streamline figures per manuscript
"""

# ╔═╡ 1347b662-fde1-4b95-acd3-9d6d9ad38c45
md"""
**Limitations**

- Only 2D visualizations ([for now](https://github.com/vega/vega/issues/1738))
- No LaTex support ([yet](https://github.com/vega/vega/issues/898))
"""

# ╔═╡ ac88ac5e-f300-456d-9ff8-972d42be14e5
md"""

**Further Resources**

- [documentation](https://vega.github.io/vega-lite/docs/)
- [example gallerie](https://vega.github.io/vega-lite/examples/)
- [vega ecosystem](https://vega.github.io/editor/#/examples/)
"""

# ╔═╡ 16c4c54e-89de-4609-a707-907971c9c29a
md"# The End"

# ╔═╡ d5130ea7-34f7-4cea-b204-47c7340c2f42
md"![](https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https://github.com/lassepe/VegaLiteIntro-slides)"

# ╔═╡ 9ada4c09-df8d-47b4-b310-ee09e97b59f1
md"<https://github.com/lassepe/VegaLiteIntro-slides>"

# ╔═╡ ea1e5ca9-7b8a-4f71-9e4c-89df3f6420ec
md"# VegaEditor"

# ╔═╡ 36773141-218b-4351-bf65-c2b7cd877c39
HTML("""
<iframe src=\"https://vega.github.io/editor/#/\"/ style=\"border: none; width: $(2*slide_width)px; zoom: 50%; height: 1000px\">""")

# ╔═╡ Cell order:
# ╟─52fdea4c-dfb2-4a60-a54d-1d31d0e5b32e
# ╠═ad3e186e-f5c8-49a3-a1d8-32f7c6d34e3c
# ╠═3ab521b5-ca30-4bd6-8a2a-93c55e91eac9
# ╠═02c5877a-2ace-45d9-b114-7c6603d887cc
# ╠═6471a65a-0ec1-441f-82eb-b0303cc0a799
# ╠═94918d60-37e7-48c8-8d08-28ad3e113960
# ╟─4f89263e-ead3-4eaf-9e1f-8c3b52dbae09
# ╟─5abb7c5a-6270-4190-8172-3dbe69980e50
# ╟─5158be6f-f83c-4805-863d-e835e0ca5a5d
# ╟─f1e8583e-e995-4e55-aeb2-db0a31cfa9a9
# ╟─c3015a6f-a4e5-431d-b010-0ff4dd0a8431
# ╟─51a6c6eb-bb4b-4301-ba37-df802f7878d0
# ╟─61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
# ╟─eccd1545-1eef-4e57-96c6-fde5090184ab
# ╟─23aa0896-a83c-4acb-b006-655c1d2e4f63
# ╠═c276c185-2442-43e2-a9c8-eba347f26715
# ╟─9df59c02-8aba-4d15-8064-33763cfdb524
# ╟─23cdd13b-4834-4fbe-9a18-b7ccec9717be
# ╟─174bddf0-a4f1-4f90-a4fe-fe1ee801c842
# ╠═77048a1e-3761-4d34-95cb-a21f253b22a5
# ╟─1a9ce711-a086-444f-b88b-86fcc3509e7f
# ╟─1562b780-2618-4eff-a582-cf6c1ffbae9b
# ╠═0a7dae00-2154-42c9-9c39-ea16aa875013
# ╠═a6cbd17a-3656-4ce8-8728-e68b97c91695
# ╟─313934df-66a9-42e9-a6d4-73f13a6c90f6
# ╟─5c09ced6-09b7-494d-a561-7484418fd08d
# ╟─ecf745b5-f33e-4512-9d9b-9ec9bdf71687
# ╠═68946680-b280-40ee-96ed-4da9ed5dc529
# ╠═6a000db6-57dd-4f26-b162-30d996f437ae
# ╟─5caa8bc7-c3ea-43f5-abd5-6f1ce9b2b43a
# ╟─d3934459-981f-42af-91c1-8000f221e43f
# ╠═581a5ad1-90ef-47d7-93e9-946bde1a0a86
# ╠═a5e112e7-581c-4a87-8f7b-183baa4a4558
# ╟─a6869f88-0d5a-41d2-9819-a189e37e282a
# ╟─29222cbd-71fe-4a26-a9cd-617fc749f058
# ╟─fd8f4530-8377-4cd0-8ba9-3d4c7619e04e
# ╟─1347b662-fde1-4b95-acd3-9d6d9ad38c45
# ╟─ac88ac5e-f300-456d-9ff8-972d42be14e5
# ╟─16c4c54e-89de-4609-a707-907971c9c29a
# ╟─d5130ea7-34f7-4cea-b204-47c7340c2f42
# ╟─9ada4c09-df8d-47b4-b310-ee09e97b59f1
# ╟─ea1e5ca9-7b8a-4f71-9e4c-89df3f6420ec
# ╟─36773141-218b-4351-bf65-c2b7cd877c39
