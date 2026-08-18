# Anti-patterns — what goes wrong

Check every chart against this catalog. If your output matches an entry, it is wrong — fix it before shipping. These are real failure modes, each caught in shipping dashboards.

## Color & encoding

**❌ Dual-axis charts** (two y-scales on one plot)
Why: The alignment of the two scales is arbitrary, so the plot invents a correlation that isn't in the data. Real example: an "Adoption" chart with Users (0–30k) and Sessions (0–800k) looked like a hallucination because the scales were misaligned.
✅ Do instead: Two separate charts, small multiples, or index both series to a common base (=100 at t0) on **one** axis.

**❌ Recolor-on-filter** (series change hue when others are hidden)
Why: A reader who learned "Acme is blue" is now misled when the color shifts.
✅ Color follows the entity, not its row number. Survivors keep their assigned hue.

**❌ Cycling / generating hues past 8**
Why: A 9th generated hue is indistinguishable from an existing slot under CVD; breaks the fixed-order mechanism.
✅ Fold the tail into "Other," facet into small multiples, or use composite encoding (hue + shape/size).

**❌ Eyeballing colorblind-safety** ("These look different enough")
Why: The method requires ≥8 ΔE (OKLab ×100) under simulated CVD. Eyeballing always fails the 6–8 floor band and hard-fails below 6.
✅ Run `scripts/validate_palette.js`. Never guess.

**❌ A value-ramp on nominal categories** (darker-where-bigger on products, teams, endpoints)
Why: Double-encodes bar length as hue; wastes the only free channel; fails the categorical checks by design (spans the band, drops below chroma floor).
✅ One series → one color (slot 1) for every bar. Ordered categories (funnel, tiers, age) → ordinal ramp with `--ordinal`.

**❌ Rainbow or non-neighbor sequential** (multi-hue magnitude ramps)
Why: Jumps between cool and warm hues read as categorical, not magnitude.
✅ One hue, light→dark. (Semantic heat or analogous neighbors are rare exceptions; always include a scale legend.)

**❌ A hue at the diverging midpoint** or **two cool/warm hues as poles** (blue↔aqua instead of blue↔red)
Why: The midpoint must read as "nothing"; poles must read as opposite. blue↔aqua fails (both cool, no contrast). blue↔red succeeds (warm/cool, clear opposition).
✅ Two hues that read as opposite + a neutral gray midpoint.

**❌ Status color used for a non-status series** or **series color used for status**
Why: Collision. A series that means "good/bad" (error rate, pass/fail) wears status. One that's just "series 4" wears categorical. Never both.
✅ Use status tokens only when the color *means* good/bad/warning/critical.

## Form

**❌ Eight categorical hues when the story is one number**
Why: The most common way a chart misses its point. Loud colors for a single headline.
✅ Emphasis (highlight one, gray the rest) or a stat tile / hero number.

**❌ A one-bar bar chart** or **a 2-slice pie**
Why: The number is louder than the shape.
✅ A stat tile. The number is the chart.

**❌ A donut or pie for comparing close values**
Why: Impossible to rank. Arcs are hard to compare when they're similar sizes.
✅ A bar chart, or the numbers in a table. Pie is only for part-to-whole at a glance, ≤6 segments.

**❌ More than ~7 color classes carrying meaning** (8+ different category colors)
Why: Adjacent classes blur at a glance; viewers can't keep track.
✅ A table, or table + chart together. Past ~7 bins, fold to "Other" or facet.

## Marks & chrome

**❌ Thick saturated blocks, heavy gridlines, no breathing room**
Why: Reads loud, even childish, at scale.
✅ Thin marks (≤24px bars), hairline recessive grid/axes (1px), generous padding. Saturated fills only for small marks and accents.

**❌ Dashed gridlines or axis rules**
Why: Dashing adds visual noise and signals "projection" or "threshold" when it's just a grid.
✅ Gridlines and axes are solid hairlines, one shade off the surface.

**❌ A number on every data point** (label on every bar, dot, or segment)
Why: Chaos. The density goes unread.
✅ Direct-label *selectively* (endpoint, extreme, the one series that matters). Let axis ticks, legend, and tooltip carry the rest. Keep labels sparse so they work.

**❌ A border drawn around marks to separate them** (strokes on every bar, segment, or dot)
Why: Adds ink that isn't data.
✅ A 2px surface gap between fills (stacked segments, adjacent bars) and a 2px surface ring (overlapping markers). Gap and ring are the separation.

**❌ A label clipped by, or overflowing, a too-small bar** (including `overflow: hidden` cropping text)
Why: Text disappears or is cut off; worse than no label.
✅ Measure first. Only render a label inside a mark when it fits with padding. Otherwise move it outside, or drop it to the tooltip/legend (value stays in the table).

**❌ A chart container whose fixed height excludes the x-axis band** (plot fits, axis labels don't, nested scroll)
Why: Defeats the point of the chart; forces users to scroll horizontally inside the card.
✅ Size the container to include the axis labels (plot height + x-axis band), or let the container grow with content.

**❌ A display or serif face on the hero figure**
Why: Reads as off-brand decoration.
✅ The hero figure uses the same sans as everything else.

**❌ `tabular-nums` on a large standalone number**
Why: Equal-width digits make `121` look loose at display sizes.
✅ Proportional figures on hero and stat-tile values; `tabular-nums` only where numbers must align vertically (table rows, axis ticks).

**❌ Texture on by default, or as decoration** (angled fill patterns always visible)
Why: Dense angled fields are a vestibular risk and read as noise.
✅ Texture is opt-in (accessibility setting, print, `forced-colors`), 45°/135° only, ordered on value scales.

## Interaction & accessibility

**❌ A tooltip as the only way to read a value**
Why: Inaccessible. Hover is not available on touch; mobile users miss the data.
✅ Tooltips enhance, never gate. Every value is also reachable via direct labels or the table view. Focus shows the same as hover.

**❌ Pinpoint hover targets** (an 8px scatter dot you must land on dead-center)
Why: Nobody hits it reliably. Frustrating on touch.
✅ ≥24px hit area including the 2px ring. For dense scatter, use nearest-point or Voronoi.

**❌ Per-chart filters** or **filters inside a chart card**
Why: Scattered controls are hard to find. Inconsistent scopes break the mental model.
✅ One filter row above everything it scopes; all charts re-render against the same slice.

**❌ Skeleton flash on refetch**
Why: Layout jump, visual distraction.
✅ Hold the previous render at reduced opacity — no skeleton, no jump, no flash.

**❌ No table view** or **color-only encoding on a continuous scale**
Why: Inaccessible. A reader who can't distinguish the colors misses the data.
✅ Every chart has a HTML table twin (the WCAG-clean equivalent). Color is an enhancement, not the channel.
