# Components — the pieces a chart is made of

A chart is assembled from these parts, all in plain HTML/SVG. The pieces stack in tiers: Tier 0 is the foundation; the System tier is what makes the method portable (and is, itself, this skill).

## Tier 0 — Color roles & foundations

- **Categorical roles** — 8 slots in both light and dark modes, assigned by identity (which series)
- **Sequential ramp** — one hue, steps 100→700, light→dark for magnitude
- **Diverging pair** — two opposite hues + neutral midpoint for polarity (above/below)
- **Status tokens** — good / warning / serious / critical for state; always icon + label paired
- **De-emphasis** — "Other" category, gray for folded or irrelevant series
- **Chart chrome** — axis, gridline, label, surface, and page-plane colors in grayscale
- **Texture fill** — one hand-drawn directional pattern (45°/135° only) inked tone-on-tone
- **Chart container** — a `<figure>` or card `<div>` that owns responsive sizing, title, caption, and the **table-view toggle** (the accessibility twin of every chart). Any fixed height includes the x-axis band so the card never gets a nested scroll; prefer letting the container grow with content.

All color roles are defined as **CSS custom properties** at the top of the HTML so light/dark values swap in one place. See `palette.md` for the template.

## Tier 1 — The standard chart types

- **Bar chart** — grouped and stacked, thin-bar default; horizontal and vertical
- **Line chart** — multi-series; soft-fill area variant with accessibility markers
- **Stat tile** — value + delta + optional sparkline (the figure contract from `marks-and-anatomy.md`)
- **Meter / progress track** — same-ramp fill on a track for progress or severity

These four cover ~90% of dashboards. Master them before reaching for others.

## Tier 2 — Rounding out the kit

- **Area chart** — stacked and banded (band-edge = line)
- **Sparkline** — 12-point minimal line for trend micro-views
- **Heatmap** — grid of cells, sequential or diverging color by magnitude
- **Scale legend** — visual guide for sequential and diverging ramps
- **Chart filters** — date range (presets + custom) and dimension pickers
- **Empty state** — fallback when no data matches the current filter

## System tier — becomes the skill

- **Six-checks validator** — `scripts/validate_palette.js` measures lightness, chroma, CVD, normal-vision, and contrast
- **Theming engine** — snap-to-passing procedure to map a customer's ramps to validated values
- **Chart-type heuristic** — pick the form by data job (`references/choosing-a-form.md`)
- **Table-view generator** — WCAG-clean text equivalent of any chart; toggled from the same container

## Assembly rules

### Legend

- Always present for ≥2 series (the dependable identity channel)
- For lines, use line-keys (2–3px strokes of the series color)
- For bars/areas, use rect swatches
- For scatter, use dots
- In tooltips, use line-keys only (no boxes)
- Single series → no legend (title names it)

### Tooltip

- On lines: vertical crosshair + one tooltip, all series at the current X
- On bars/cells: per-mark tooltip, value-first, line-key per series
- Hit area ≥24px (scatter), or crosshair snap (line/bar)
- Keyboard focus shows the same as hover

### Direct labels

- Selectively (endpoint, extreme, or the one series that matters)
- Inside marks only if they fit with padding; otherwise tooltip + table
- Never a number on every point
- Text never wears the series color

### Table view

- The WCAG-clean twin of the chart; toggle inside the container
- Every value in the chart, every series, every category
- No color required; rows, cols, headers in text
- Reachable without hovering

## Anti-patterns to check

- **No dual-axis charts** — arbitrary scale alignment invents false correlations
- **No more than one direct label per series** — labels at the endpoint only
- **No borders around marks** — use 2px surface gaps (stacked, bars) and rings (markers)
- **No dashed gridlines** — solid hairlines only
- **No `tabular-nums` on hero figures** — proportional figures only for big standalone numbers
- **No decoration texture** — texture opt-in only (a11y, print, `forced-colors`)
- **No tooltip-only values** — every number lives in labels or the table too
- **No generation of a 9th categorical hue** — fold to "Other," facet, or composite-encode

See `anti-patterns.md` for the full catalog.
