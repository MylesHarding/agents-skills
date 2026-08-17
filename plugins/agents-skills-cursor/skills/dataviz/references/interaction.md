# Interaction — tooltips & filters

An HTML chart is interactive by default — the hover layer is part of the deliverable, not an upgrade. Omitting it is the exception (a bare stat tile), never the default. Design the interaction layer with the same care as the static render.

## Tooltips & hover layer

Tooltips **enhance, they never gate.** Every value a tooltip shows must be reachable without it — through direct labels or the table view. Same details on keyboard focus as on hover. If the only way to read a value is by hovering, the chart failed accessibility.

### For line and bar charts

**The crosshair** — A vertical hairline tracks the pointer and snaps to the nearest data position on the X-axis. Readers aim at a date or category, not at a 2px line. On line charts, the crosshair hits every series at the same X and shows the complete tooltip (all series values at that position).

**The tooltip** — lists every series at the current X, one row per series. Value first (strong, high-contrast, the thing the reader is looking for), series name second (secondary text). Use a short line-key (2–3px stroke of the series color) to key each row, not a filled box — at tooltip density, boxes are excessive ink.

### For bar, cell, and marker charts

No crosshair. Instead, **each mark carries its own tooltip** showing category and value. On hover and focus, the mark lifts slightly (lighten or outline) so the reader sees it respond. The hit target is generous (see "Hit targets" below) so the pointer doesn't have to be dead-center on a small mark.

### Tooltip content

- **Lead with the value,** not the label. The reader has the series (from the legend) and wants the number.
- **Series names are untrusted data.** Use `textContent` or `createTextNode` to insert them into the DOM, never `innerHTML` string concatenation. Series and category names often come from CSV headers, tool output, or API responses.
- **Every series at the current position.** The pointer never has to land on a specific line or fill to get a value. One X, one tooltip, all series.

### Hit targets

- **≥ 24px hit area** for scatter points and markers. An 8px dot is a pinpoint nobody hits reliably on the first try.
  - Include the 2px surface ring as part of the hit area.
  - For dense scatter, use a nearest-point or Voronoi layer so the pointer only has to be *closest*, not dead-center.
- **The crosshair already does this for X on line and bar charts** — the snap-to-nearest behavior makes the X-axis responsive without requiring pixel-perfect aim.
- **A value pushed off its mark lives in the tooltip.** When a label won't fit inside a small bar (see `marks-and-anatomy.md`), that bar's hit area carries the value on hover and focus. The tooltip is the overflow home; the table view keeps it reachable without hovering.

### Keyboard navigation

- **Every interactive element has focus states.** Hover and focus show the same tooltip; the focus ring is always visible.
- **Tab order follows left→right, top→bottom,** matching reading order.
- **Enter or Space on a legend item should toggle or isolate** that series (if toggling is supported).

## Filters & time ranges

Every monitoring dashboard needs the same controls. Filters are **standard UI (HTML form controls), not chart marks** — build them with ordinary inputs and selects styled to match the chart chrome. Dataviz adds only composition rules:

### Placement & scope

- **One row, above the charts.** Filters sit in a single left-aligned row above the content they scope — never inside a chart card, never per-chart (if one chart needs its own range, that's a different dashboard).
- **Filters scope everything below them.** Every chart, stat, and table re-renders against the same slice. The numbers always agree across the dashboard.

### Date range

- **Date range is first.** It's the filter every reader reaches for.
- **Presets before custom.** Offer rows: today, last 7 days, last 30 days, last 90 days, month-to-date. Mark selection with a 16px bold check.
- **Hover is a ghost wash,** so it never competes with selection.
- **Custom range is behind a hairline** in the footer of the picker — accessible, not in the way.

### Refetch behavior

- **While data reloads, hold the previous render at reduced opacity** — no skeleton screens, no layout jump, no flash. The viewer's context stays stable while new data arrives.
- **All charts re-render on the same new dataset.** No per-chart staggering or race conditions.

### Dimension filters

**Standard combobox.** Searchable if the dimension has many values; otherwise a dropdown list. Follow platform conventions (native `<select>` if possible, or a styled combobox with ARIA roles).

### Summary

Filters are a **mechanical layer above the charts, not part of the chart design itself.** Dataviz specifies only where they live (above) and what they do (re-render everything below against a single slice). The UI implementation (color, padding, font, interaction) follows the system's form-control conventions.
