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
	using VegaLite: @vlplot
	import PlutoUI
	import HypertextLiteral: @htl
end;

# ╔═╡ 3ab521b5-ca30-4bd6-8a2a-93c55e91eac9
slide_width = 1400;

# ╔═╡ 6471a65a-0ec1-441f-82eb-b0303cc0a799
@htl("""
<style>
main {
	max-width: $(slide_width)px;
}
""")

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
# TL;DR: Grammar of Graphics

- **Data** is assumed to be given in a tabular format.

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
- `DataFrame`
- An iterable of `NamedTuple` or `Dict`.
- YAML, CSV, JSON
"""

# ╔═╡ 45f41399-b386-4897-9860-ee80e012e2f0
md"# A Simple Plot"

# ╔═╡ c276c185-2442-43e2-a9c8-eba347f26715
scatter_plot = let
	@vlplot(
		width = slide_width,
		mark = {"point", filled = true, opacity = 0.2},
		encoding = {
			x = "time:q",
			y = "amplitude:q",
		},
	)
end;

# ╔═╡ 1562b780-2618-4eff-a582-cf6c1ffbae9b
md"""
# A Simple Plot
"""

# ╔═╡ 06e52c18-95c7-46a7-b9cb-2e8a47cd19d3
@htl(
"""
<table style="margin: 0;">
	<tr>
	<th>Window Size</th>
	<td>$(@bind window_size PlutoUI.Slider(2:2:40; show_value=true, default = 20))</td>
	</tr>
	<tr>
	<th>Noise σ</th>
	<td>$(@bind σ PlutoUI.Slider(0.0:0.01:1.0; default=0.5, show_value = true))</td>
	</tr>
</table>
 </br> 
""")

# ╔═╡ 61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
data = begin
	Δt = 0.01
	((time, amplitude = sin(time) + σ * randn()) for time in 0:Δt:2π) |> DataFrame
end

# ╔═╡ 77048a1e-3761-4d34-95cb-a21f253b22a5
scatter_plot(data)

# ╔═╡ 0a7dae00-2154-42c9-9c39-ea16aa875013
let
data |>
@vlplot(
	width = slide_width,
	height = 200,
) +
@vlplot(
	mark = {"point", tooltip = {content = "data"}, filled = true, opacity = 0.2},
	x = "time:q",
	y = "amplitude:q"
) +
(
	@vlplot(
		transform = [
			{
				window = [
					{field = "amplitude", op = "mean", as = "rolling_average"},
					{field = "amplitude", op = "ci0", as = "rolling_lower"},
					{field = "amplitude", op = "ci1", as = "rolling_upper"},
				],
				frame = [-window_size/2, window_size/2]
			}
		],
	) +
	@vlplot(
		mark = "line",
		x = "time:q",
		y = "rolling_average:q",
	) +
	@vlplot(
		mark = "errorband",
		x = "time:q",
		y = "rolling_lower:q",
		y2 = "rolling_upper:q"
	)
)
end

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
# ╠═6471a65a-0ec1-441f-82eb-b0303cc0a799
# ╟─4f89263e-ead3-4eaf-9e1f-8c3b52dbae09
# ╟─5abb7c5a-6270-4190-8172-3dbe69980e50
# ╠═5158be6f-f83c-4805-863d-e835e0ca5a5d
# ╟─f1e8583e-e995-4e55-aeb2-db0a31cfa9a9
# ╟─c3015a6f-a4e5-431d-b010-0ff4dd0a8431
# ╟─51a6c6eb-bb4b-4301-ba37-df802f7878d0
# ╟─61b8b0a0-f1e2-4ccb-828f-c54fe2a721aa
# ╟─45f41399-b386-4897-9860-ee80e012e2f0
# ╠═c276c185-2442-43e2-a9c8-eba347f26715
# ╠═77048a1e-3761-4d34-95cb-a21f253b22a5
# ╟─1562b780-2618-4eff-a582-cf6c1ffbae9b
# ╟─06e52c18-95c7-46a7-b9cb-2e8a47cd19d3
# ╠═0a7dae00-2154-42c9-9c39-ea16aa875013
# ╟─29222cbd-71fe-4a26-a9cd-617fc749f058
# ╟─16c4c54e-89de-4609-a707-907971c9c29a
