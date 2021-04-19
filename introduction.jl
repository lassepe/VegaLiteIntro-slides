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

- Vega Lite is a JSON *specification* for mapping data to visualization
- Based on Leland Wilkinsons's *grammar of graphics* (c.f. `ggplot2`)
- Various frond-ends can generate `.vl.json` spec files:
  - JavaScript: `vega-lite.js`
  - Julia: `VegaLite.jl`
  - Python: `Altair`
"""

# ╔═╡ f1e8583e-e995-4e55-aeb2-db0a31cfa9a9
md"""
# Grammar of Graphics -- TL;DR

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
- Language internal: `DataFrame`, iterable of `NamedTuple` or `Dict`.
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

# ╔═╡ b66c9dd5-e46e-4d17-8d93-1fa0af1cc871
md"**Pass data to the spec-object for visualization**"

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

# ╔═╡ fdb12d82-247b-44f9-8c9d-121543680086
md"# Saving and Loading Specifications"

# ╔═╡ 81dd099d-72e2-4748-bd2f-f860167acac4
PlutoUI.RemoteResource("https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png")

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
# ╟─6471a65a-0ec1-441f-82eb-b0303cc0a799
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
# ╟─b66c9dd5-e46e-4d17-8d93-1fa0af1cc871
# ╠═77048a1e-3761-4d34-95cb-a21f253b22a5
# ╟─1a9ce711-a086-444f-b88b-86fcc3509e7f
# ╟─1562b780-2618-4eff-a582-cf6c1ffbae9b
# ╠═0a7dae00-2154-42c9-9c39-ea16aa875013
# ╠═a6cbd17a-3656-4ce8-8728-e68b97c91695
# ╟─313934df-66a9-42e9-a6d4-73f13a6c90f6
# ╟─fdb12d82-247b-44f9-8c9d-121543680086
# ╠═81dd099d-72e2-4748-bd2f-f860167acac4
# ╟─29222cbd-71fe-4a26-a9cd-617fc749f058
# ╟─16c4c54e-89de-4609-a707-907971c9c29a
