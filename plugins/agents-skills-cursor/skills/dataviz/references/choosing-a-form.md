# Choosing a form

Decide the chart form **before** assigning color. The data's job picks the shape — and sometimes the right form is not a chart at all.

## Is it even a chart?

Many datasets don't need one:

| The data is… | Use | Not |
|---|---|---|
| A single current value (+ maybe a trend) | **Stat tile** (value + delta + sparkline) | A one-bar bar chart |
| A handful of headline numbers | **KPI row** of stat tiles | A grouped bar chart |
| The one number a dashboard leads with | **Hero figure** (≥48px, sans serif) | — |
| A single ratio against a limit | **Meter** (same-ramp track with fill) | A pie of 2 slices |
| More than ~7 classes that all carry meaning | A **table** (or table + chart together) | More colors |

If a chart is the right form, pick the type by the job the reader must do:

## The job → the form

| Job (what the reader must do) | Default form | Color job |
|---|---|---|
| Compare magnitude, low → high | bar / column; **heatmap** for a 2D grid | sequential (one hue, light→dark) |
| Trend over time | line; area for a single series | sequential or 1 categorical slot |
| Tell distinct series apart (≤ 8) | grouped/stacked bar, multi-line | **categorical** (8 hues, assigned by slot) |
| One series is the story, rest is context | **emphasis** (highlight one, gray the rest) | 1 accent hue + de-emphasis gray |
| Above/below a baseline; difference to target | diverging bar, or line vs baseline | **diverging** (two hues + neutral midpoint) |
| Part-to-whole, ≤ 6 segments | **stacked bar** (horizontal for long names) | categorical |
| Ordered-scale share (Likert, sentiment) | **diverging stacked bar**, centered | diverging |
| Before → after per item | dumbbell (two marks per row) | 1 hue, 2 shades |

## The rules behind the table

**Sequential is the safe default.** One hue, light→dark (or dark→light in dark mode). It stays legible, stays consistent, and is hard to misread. Reach for it unless the data's job is specifically *identity* (which series?) or *polarity* (which side of zero?).

**Categorical** is for when *which series* is the point. It carries a real cost: the story can get buried under nine competing colors. If the story is "this one went up," that's **emphasis**, not categorical — use one accent hue and gray out the rest.

**Emphasis** is the most underused form. One series in the accent hue, the rest in de-emphasis gray. Often the honest answer to "make this clearer" — one honest line, others faded.

**Texture** is opt-in, not a default form. It earns its place for accessibility (full CVD, print, `forced-colors`), never for decoration. See `marks-and-anatomy.md`.

## Series count and series cap

How many things can live on one chart without becoming a confused mess?

| Series | Treatment |
|---|---|
| 1 | Color is the slot 1 hue; no legend needed (title names the series). |
| 2–3 | Color alone is comfortable for everyone. Direct-label and move on. |
| 4 | Adjacent forms (stacks, bars, lines) stay passable, but direct labels become mandatory — yellow and orange now share the screen; all-pairs forms (scatter, bubble, choropleth, small multiples) cap at **three** — fold to "Other" or facet. |
| 5–6 | Soft cap; legend or small multiples. |
| 7–8 | Token ceiling (the eight categorical slots). Past it, fold the tail into "Other," facet into small multiples, or composite-encode (hue + shape). |
| ≥9 | **Never generate a 9th hue.** A generated slot is indistinguishable from an existing one under CVD and breaks every check. Fold or facet instead. |

**Series cap on all-pairs forms** (scatter, bubble, choropleth, small multiples where any two marks can sit side by side): the reference palette validates only the first three slots all-pairs in both modes. The fourth slot puts yellow and orange together, and that pair fails the all-pairs floors. If you need four or more series, **fold the tail into "Other," facet into small multiples, or use a composite encoding (hue + shape / hue + size).**

## Anti-pattern check

- **Dual-axis charts:** The alignment is arbitrary, so the plot invents correlations that aren't in the data. Use two charts, small multiples, or index both to a common base (=100 at t0) on one axis.
- **One-bar bar chart:** A stat tile is better. The number is the chart.
- **Pie/donut for close values:** A bar is clearer. Pie/donut only for part-to-whole at a glance, ≤6 segments.
- **Eyeballed colorblind-safety:** Run the validator. Never guess.
