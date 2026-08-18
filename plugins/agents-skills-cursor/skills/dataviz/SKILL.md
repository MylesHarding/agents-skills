---
name: dataviz
description: "Design charts, dashboards, and stat tiles using a color-formula validator and the accessibility pass. Seven-step procedure: form selection → color assignment → palette validation → mark specs → hover layer → accessibility → render and check. Covers chart-type heuristics (magnitude, identity, polarity, headline, change-over-time), the six validation checks (lightness band, chroma floor, CVD separation, normal-vision floor, contrast, documented-palette-only), mark anatomy (thin bars, rounded data-ends, surface gaps), interaction specs (crosshairs, tooltips, filters), and how to plug into an existing design system. Use whenever a task involves a chart, dashboard, data table, stat tile, or any color-by-status decision."
---

# dataviz

Design charts and dashboards where color carries meaning and stays accessible. This skill provides a deterministic method: pick the chart form, assign colors by job (not taste), validate against six measurable checks, spec the marks and interaction, and verify the render. The method is language-agnostic and portable across design systems.

## The seven-step procedure

### 1. Choose the form

The data's job picks the chart type. A magnitude comparison calls for bars or a heatmap; a trend over time calls for lines; identity among series calls for grouped bars or a categorical encoding. Start here and color flows from the choice, not the other way around.

Use `references/choosing-a-form.md` to pick:
- **The form** — bar, line, heatmap, stacked, area, stat tile, meter, or in some cases a table
- **The color job** — categorical (identity), sequential (magnitude), diverging (polarity), status (state)
- **The series count** — how many things are competing for attention on screen

If the right form is not a chart, say so. A single current value is a **stat tile**, not a one-bar chart. The headline numbers are **KPI rows**, not grouped bars.

### 2. Assign colors by job

Every color does exactly one of four jobs:
- **Categorical** — which series (8 hues, fixed order, never cycled)
- **Sequential** — magnitude, low to high (one hue, lightness steps)
- **Diverging** — polarity, above/below a baseline (two hues + neutral midpoint)
- **Status** — state, good/warning/serious/critical (fixed meaning, icon + label required)

Do not eyeball. Use your system's palette (`palette.md` in this skill) and assign slots by job. A single series wears slot 1 and no legend. Two to three series take slots 1–3. More than three series in an all-pairs chart form (scatter, bubble, choropleth) is a series cap — fold to "Other" or facet instead.

### 3. Validate the palette

Before you render, run the validator to confirm the palette passes all six checks. This is where color science lives: the checks compute lightness bands, chroma floors, CVD separation, normal-vision distinctness, and contrast — never eyeballed, always measured.

```
node scripts/validate_palette.js "#2a78d6,#eb6834,#1baf7a,#eda100,#e87ba4,#008300,#4a3aa7,#e34948" --mode light
```

Read `references/color-formula.md` for the detailed check definitions and what to do when the validator warns or fails. A WARN on CVD (the 6–8 floor band) is legal only if you add secondary encoding: direct labels, gaps, or texture. A FAIL means re-step the palette or reduce the series count.

### 4. Spec the marks and spacing

Marks are minimal and consistent: thin bars (≤24px), 2px lines with round joins, ≥8px markers. Spacing is deliberate: a 2px surface gap between stacked segments and adjacent bars, a 2px surface ring around markers so they stay legible where they overlap.

See `references/marks-and-anatomy.md` for:
- Bar thickness and rounding specs
- Line weight and joins
- Marker sizes and surface rings
- Direct labels (endpoint, extreme, or the one series that matters — never a number on every point)
- Legend rules (always present for ≥2 series; use line keys in tooltips, not boxes)

### 5. Design the hover layer and tooltips

The hover layer is part of the deliverable, not an upgrade. Every value a tooltip shows must be reachable without hovering — through direct labels or the table view. Tooltips enhance, never gate.

See `references/interaction.md` for:
- Crosshair behavior (vertical hairline tracks the pointer, snaps to the nearest data position)
- Tooltip content (every series at the current X; value first, label second)
- Hit-target sizing (≥24px for scatter; crosshair for line/bar charts)
- Filter row placement (above the charts; date range first; all charts re-render against the same slice)

### 6. Verify accessibility

Before shipping:
- **Color alone never encodes.** A color-blind reader must understand the chart without color — use texture, labels, or shape as a second encoding.
- **Contrast ≥3:1** on marks vs the chart surface; ≥4.5:1 for text.
- **Table view.** Every chart has a HTML table twin — the fallback when color fails or the user prefers text.
- **Keyboard navigation.** Hover and focus show the same tooltip; the focus ring is always visible.
- **Texture.** Opt-in (accessibility setting, print, `forced-colors`), never on by default; 45° and 135° only.

### 7. Render and cross-check

Build the chart in HTML/SVG using plain color roles as CSS custom properties (see `palette.md` for the template). Link the table view inside the chart container so it toggles on demand.

Before merging:
- Check the chart against `references/anti-patterns.md` — if it matches an entry, it is wrong.
- Run the chart through a colorblind simulator (Coblis, Color Oracle) with the palette you shipped.
- Test keyboard navigation on every interactive element.
- Verify the table view is complete and accurate.

---

## Non-negotiables

These rules apply to every chart, regardless of system or framework:

| Rule | Why | What to do if you hit it |
|---|---|---|
| Form before color | Picking color first locks you into bad forms (rainbow ramps, dual axes). | Name the job. Start with `references/choosing-a-form.md`. |
| Color by job, not taste | Hand-picked colors almost never pass the checks. The method is deterministic. | Use `palette.md` and assign by slot. Eyeballing is not allowed. |
| Validate before render | A palette that passes in light mode may fail in dark, or fail on all-pairs scatter. | Always run `scripts/validate_palette.js` with your exact mode and surface before shipping. |
| Secondary encoding for sub-3:1 contrast | A yellow series on a light surface is below 3:1 WCAG. Shipping it alone is inaccessible. | Add a visible direct label or move to the table view. Icon + label pairs are the mitigation. |
| Never cycle past 8 categorical hues | A 9th generated hue is indistinguishable from existing slots under CVD. | Fold to "Other," facet into small multiples, or use composite encoding (hue × shape). |
| Tooltips enhance, never gate | If the only way to read a value is by hovering, the chart failed accessibility. | Direct-label key values; always include a table view. The tooltip is a luxury, not a lifeline. |
| Marks carry color, text doesn't | A light categorical hue (yellow, aqua) is illegible as text. Identity comes from the colored mark beside the text. | Color bars, lines, dots; use ink or white text by fill luminance. Text always uses text tokens (primary/secondary). |
| One consistent spacing rule | Mixing 2px gaps and 4px gaps creates visual noise and looks hand-assembled. | Every stacked segment and adjacent bar: 2px surface gap. Every marker: 2px surface ring. |

---

## Plugging into an existing design system

When you have a system's own ramps instead of the reference palette:

1. **Map the four jobs** to your system's color roles. Do you have eight categorical hues? A sequential single-hue ramp? A diverging pair? Status tokens?
2. **Run the six-checks validator** against your system's palette, with your own light and dark surfaces:
   ```
   node scripts/validate_palette.js "<your-hex-list>" --mode light --surface "<your-light-surface>"
   node scripts/validate_palette.js "<your-hex-list>" --mode dark --surface "<your-dark-surface>"
   ```
3. **If it fails**, either:
   - **Snap to passing** — shift each slot ±1 step in lightness (hold the hue) until the worst adjacent pair clears the floor. See `references/color-formula.md` § Snap-to-passing.
   - **Re-order the slots** — the slot *order* is a named choice (a theme). If your system has hues but no default order, enumerate candidate orderings and pick the one with the highest minimum adjacent CVD ΔE. The documented palette in this skill came from exactly that enumeration.
4. **For sequential/diverging ramps**, validate with `--ordinal` (discrete ordered marks) or check lightness monotonicity by hand.
5. **Lock the palette instance** in your own `palette.md` — every slot is a documented hex, never regenerated or eyeballed. When you swap palettes, swap the file; never touch the method.

---

## Troubleshooting

| Symptom | Check |
|---|---|
| "This palette is too muted" | Chroma floor is below 0.10 OKLCH. Nudge the slots +0.01 C (shift the step slightly toward the hue's pure point). Run the validator again. |
| "Adjacent slots look too similar" | Normal-vision floor is below 15 ΔE (OKLab ×100, unsimulated). Re-step one of the pair; re-ordering alone won't fix it. |
| "Colorblind readers are confusing slot 2 and 4" | CVD ΔE on that pair is below 8 (or 6 with secondary encoding). If you have secondary encoding (labels, gaps, texture), accept the WARN. Otherwise, re-order or re-step. |
| "I need 12 categories" | That's above the series cap. Fold the tail into "Other" (relabeled in the tooltip), facet into small multiples, or use composite encoding (hue + shape). The all-pairs validation is a hard gate; no palette change can fix it. |
| "Can I use a different colorblind simulation model?" | No. The CVD thresholds are calibrated to Machado–Oliveira–Fernandes (2009) at severity 1.0. Swapping simulators changes the boundaries and would require recalibrating thresholds. The model is part of the standard, not an implementation detail. |
| "Our design system uses named color tokens instead of hex values" | Map each token to its hex output and feed the hex list to the validator. The checks operate on computed RGB; the token system is a layer above. |

---

## References

- `references/choosing-a-form.md` — Chart type by data job (magnitude, identity, polarity, headline, change-over-time)
- `references/color-formula.md` — The six validation checks and snap-to-passing rules
- `references/marks-and-anatomy.md` — Mark specs, spacing, direct labels, legend and figure rules
- `references/interaction.md` — Hover behavior, tooltips, crosshairs, filter placement
- `references/components.md` — The pieces charts are made of (color roles, texture, containers, legends)
- `references/anti-patterns.md` — Catalog of what goes wrong (dual axes, rainbow ramps, pinpoint hovers, and 10 more)
- `references/palette.md` — The reference palette instance and CSS template for plugging values into charts
- `scripts/validate_palette.js` — Node.js validator; `node scripts/validate_palette.js "<hex-list>" --mode light`
