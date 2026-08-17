# Marks & anatomy

The quiet, considered look is a few fixed specs plus deliberate negative space. Data is the only thing allowed to be loud.

## Mark specifications (fixed across every chart)

| Mark | Specification |
|---|---|
| **Bar / column** | ≤ 24px thick (cap it — never fill the slot; let the band's leftover be air); 4px rounded data-end, square at the baseline; grows from a single baseline |
| **Line** | 2px stroke weight, round join and cap |
| **Marker / end-dot** | ≥ 8px diameter (radius ≥ 4px), filled with the series color |
| **Area fill** | The series hue at ~10% opacity (a wash, never a saturated block) |
| **Gridlines / axes** | One shade off the surface, hairline (1px), solid (never dashed), recessive |

These are not recommendations — they are constants. A 40px bar on one chart and 16px on another reads inconsistent. Keep marks fixed so viewers build a visual grammar.

## The two spacers (surface color for separation)

**Surface gap:** Every 2px gap in the surface color separates touching marks — every segment of a stacked bar, and every adjacent (touching) bar — at a consistent width. When neighbors are one step apart in color, the gap is what makes them read distinct, not a stroke drawn around them. Keep the width one consistent 2px across a stack.

**Surface ring:** Dots and end-markers carry a 2px ring in the surface color, so they stay legible where they cross a line or overlap each other. The ring is part of the mark's hover/hit target, not just cosmetic spacing. See `interaction.md` for hit-target sizing.

Never draw a border around a mark. The gap and the ring are the separation mechanism; a stroke adds ink that isn't data.

## Labels & legend

**Always use a legend for ≥2 series** — the dependable identity channel. Never make the reader rely on color-matching alone. Direct labels then supplement the legend.

**A single series needs no legend box.** There is only one color, so the chart title or subtitle already says what is plotted. A legend box with one swatch restates the title and wastes space.

### Direct labels

- **Label selectively — never a number on every point.** A value beside every dot or segment is visual chaos and goes unread. Label the endpoint, the extreme, or the one series that is the story. Let the axis ticks, the legend, and the tooltip carry everything else.
- **Direct labels work *because* they are sparing.** Flood the chart and they stop working.
- **Direct labels come before gridlines; gridlines before a second axis.** If you are considering a second y-axis, facet or use small multiples instead (see anti-patterns).
- **A label that doesn't fit doesn't get clipped.** Measure first. Only render a label inside a bar or stacked segment when the text fits comfortably with padding on both sides. If it doesn't:
  - For a whole bar/column: move the label to the outside of the bar end, or to the tooltip.
  - For an interior stacked segment (which has no free end): skip the inline label. The legend and tooltip carry the series; the table view carries the value.
  - Never use `overflow: hidden` to crop the label — that removes characters and is worse than no label.
- **Value placement by form:**
  - Bars → value at the tip
  - Columns → value on the cap
  - Lines → value at the end
- **Y-axis ticks:** Round to clean numbers (0 / 1,000 / 2,000), thousands-comma'd. They carry the values you didn't directly label, so keep them unless every data point is labeled.

### Legend

- **Text never wears the data color.** Marks (bars, lines, dots, area fills) carry the series color. Labels, values, legends, and axis text use text tokens (primary / secondary / muted). A light categorical hue (yellow, aqua) is illegible as text on the surface.
- **Identity comes from the colored mark *beside* the text**, not from coloring the text itself. In the legend, use a short line-key (for lines), a small rect (for bars/areas), or a dot (for scatter) in the series color, followed by the label in text tokens. The mark identifies; text names.
- **One exception:** A label rendered *inside* a colored fill (a stacked segment, a map tile) must pick white or ink by the fill's luminance to clear contrast.
- **Line keys in tooltips, not legend boxes.** At tooltip density, a filled box is data-weight ink doing a label's job. Use a short stroke of the series color instead.

### End-label collisions

When end-labels collide (lines converge at the right edge), don't stack them vertically:
- Stacking detaches labels from their lines and reads as noise.
- Instead, use **leader lines** (a thin connector from label to line-end).
- Or, facet into **small multiples** — one mini-chart per series.
- Or, fall back to the legend + tooltip.
- Past ~4 converging series, small multiples is usually the right call.

## Figures — when the form is a number

**Stat tile** contract: `label` (sentence case, no trailing colon) · `value` (sans serif, semibold, auto-compact: 1,284 / 12.9K / $4.2M) · `delta` (optional; signed, vs a named period; color = direction × whether up is good) · `trend` (optional; 12-point sparkline in the de-emphasis hue, current period in accent).

**Meter / progress track:** The fill carries severity (accent → warning → danger). The unfilled track is a lighter step of the same ramp (blue-on-blue, etc.) so state reads across the whole bar.

**Hero figure:** The single number a dashboard leads with. ≥ 48px at display sizes, rendered in the system sans serif (never a display or serif face — it reads as off-brand decoration). Exactly one per view.

**Proportional figures for big numbers; tabular only in columns:** A large standalone value (hero figure, stat-tile value) uses the font's default proportional figures — `tabular-nums` gives every digit the width of a `0`, so a number like `121` looks loose at display sizes. Reserve `font-variant-numeric: tabular-nums` for columns of numbers that must align vertically (table rows, axis ticks).

## Texture — the backup channel (opt-in)

Where hue fails — full-severity CVD, grayscale print, `forced-colors` — texture carries identity. One directional hand-drawn fill pattern, used at **45° and its 135° mirror only** (never horizontal or vertical — those read as gridlines or bar borders).

**Pattern:** Inked tone-on-tone (a darker step from the fill's own ramp), equal loudness across all slots. On value scales (sequential, diverging), the texture is *ordered* — rotation steps with magnitude (45° for low values, 135° for high), and arm angle carries the diverging sign (45° for above-baseline, 135° for below) — so texture never misstates the value.

**When to use:** Triggered by an accessibility setting, print export, or `forced-colors` media query — never on by default. Texture on by default reads as noise and is a vestibular risk for motion-sensitive users.

**With categorical:** Each slot gets the same pattern (45° only), inked in its own step's darker shade. Swapping rotations per slot defeats the purpose — all categorical uses 45°.

**With sequential/diverging:** Rotation carries magnitude; angle carries sign. This makes texture a legible channel when color is gone.
