# Reference palette

This is the **reference instance** of the dataviz method: every parameter the method requires, filled with a validated default palette. The rest of the skill is system-agnostic — **to target your brand, substitute this file's values** and re-run the validator. Nothing else changes.

## How to use these values

Everything below is plain hex. In an HTML chart, **define the slots you use as CSS custom properties in a local `<style>` block** at the top of the file, then reference them by role throughout — so light/dark values swap in one place and the chart body is written against roles rather than raw hex.

```css
:root {
  color-scheme: light;
  --surface-1:      #fcfcfb;   /* chart surface */
  --text-primary:   #0b0b0b;
  --text-secondary: #52514e;
  --series-1:       #2a78d6;   /* categorical slot 1 */
  --series-2:       #eb6834;   /* categorical slot 2 */
  /* …only the roles this chart uses */
}
@media (prefers-color-scheme: dark) {
  :root:where(:not([data-theme="light"])) {
    color-scheme: dark;
    --surface-1:      #1a1a19;
    --text-primary:   #ffffff;
    --text-secondary: #c3c2b7;
    --series-1:       #3987e5;
    --series-2:       #d95926;
  }
}
:root[data-theme="dark"] {
  color-scheme: dark;
  --surface-1:      #1a1a19;
  --text-primary:   #ffffff;
  --text-secondary: #c3c2b7;
  --series-1:       #3987e5;
  --series-2:       #d95926;
}
```

Declare the dark values under both scopes as above — the `@media` query covers the OS setting; the `[data-theme="dark"]` scope covers the viewer's theme toggle, which must win both ways. The `:not([data-theme="light"])` guard lets a light stamp beat OS-dark when needed.

## Categorical palette

Both modes are selected. The dark column is the same eight hues re-stepped for the dark surface, not a separate palette.

| Slot | Hue | Light | Dark |
|------|-----|-------|------|
| 1 | blue | `#2a78d6` | `#3987e5` |
| 2 | orange | `#eb6834` | `#d95926` |
| 3 | aqua | `#1baf7a` | `#199e70` |
| 4 | yellow | `#eda100` | `#c98500` |
| 5 | magenta | `#e87ba4` | `#d55181` |
| 6 | green | `#008300` | `#008300` |
| 7 | violet | `#4a3aa7` | `#9085e9` |
| 8 | red | `#e34948` | `#e66767` |

This order passes every hard gate in both modes on the **adjacent** pairlist (stacks, bars, lines):
- Worst adjacent CVD ΔE: 9.1 light / 8.4 dark (OKLab ×100, ≥8 target)
- Worst adjacent normal-vision ΔE: 19.6 light / 19.3 dark (≥15 floor)

Under `--pairs all` (scatter, bubble, choropleth, small multiples where any two marks can sit side by side), **the first three slots validate all-pairs in both modes:**
- Worst all-pairs CVD ΔE: 9.2 light / 9.4 dark
- Worst all-pairs normal-vision ΔE: 24.0 light / 20.9 dark

**Series cap on all-pairs forms:** Past three, fold to "Other" or facet. The fourth slot puts yellow and orange together, and that pair fails the all-pairs floor (normal-vision 13.7 light; CVD 4.8 dark). More than three series on an all-pairs chart is a series cap binding — reduce series count, facet, or switch form.

**Contrast on light surface:** Three slots sit below 3:1 contrast: magenta (2.67:1), yellow (2.57:1), aqua (2.95:1). The **relief rule** applies — ship visible direct labels or the table view for these slots.

**Dark steps:** Chosen for the dark band (OKLCH L ≈ 0.48–0.67) and validated as a set. All clear ≥3:1 on the dark surface and remain distinct from categorical slots.

**Ordering history:** Adopted in July 2026 for more harmonious opening colors. Same eight hues and steps as its predecessor, re-ordered, zero hex changes. The predecessor validated its first four slots all-pairs; this order deliberately trades that fourth slot for better-looking leading colors. Revisit the trade if yellow↔orange confusion shows up in real charts with four or more series.

**The slot order is the CVD-safety mechanism, not cosmetic.** When you swap in your brand's hues, enumerate candidate orderings, run the validator on each, and choose only among the passing ones.

## Sequential hue

Default single hue: **blue**, light→dark. When two sequential contexts appear together, the second takes the next categorical slot's hue (orange), each as its own one-hue ramp.

| step | hex | step | hex | step | hex | step | hex |
|---|---|---|---|---|---|---|---|
| 100 | `#cde2fb` | 250 | `#86b6ef` | 400 | `#3987e5` | 550 | `#1c5cab` |
| 150 | `#b7d3f6` | 300 | `#6da7ec` | 450 | `#2a78d6` | 600 | `#184f95` |
| 200 | `#9ec5f4` | 350 | `#5598e7` | 500 | `#256abf` | 650 | `#104281` |
| | | | | | | 700 | `#0d366b` |

The full 100→700 range is for **sequential** encoding (continuous magnitude — heatmaps, choropleths) where the lightest step means "near zero" and is allowed to recede toward the surface.

For an **ordinal** ramp (discrete ordered marks — funnel stages, tiers — validated with `--ordinal`), the lightest step on a light surface must still clear 2:1 contrast. On light, start no lighter than **step 250** (`#86b6ef`, 2.06:1). On dark, go no darker than **step 600** (`#184f95`, 2.15:1).

## Diverging pair

**blue ↔ red** — warm/cool poles that read as opposite. Neutral midpoint is gray:
- Light midpoint: `#f0efec` (neutral gray, low saturation)
- Dark midpoint: `#383835` (neutral gray, matches dark surface band)

Equal step count per arm. Blue steps mirror the sequential ramp above; red steps are a symmetric counterpart.

## Status palette (fixed — never themed)

Status never follows the theme — it is a small fixed scale with reserved meaning, on steps deliberately distinct from categorical slots so a status color never impersonates a series. Always paired with an icon + label.

| Role | Light hex | Light contrast | Dark hex | Dark contrast |
|---|---|---|---|---|
| good | `#0ca30c` | 3.27:1 | `#0ca30c` | 5.19:1 |
| warning | `#fab219` | 1.79:1 | `#fab219` | 9.49:1 |
| serious | `#ec835a` | 2.57:1 | `#ec835a` | 6.60:1 |
| critical | `#d03b3b` | 4.68:1 | `#d03b3b` | 3.62:1 |

**Light surface:** warning (1.79:1) and serious (2.57:1) are below 3:1 by design — the icon + label pairing is the mitigation. Never ship a status color alone.

**Dark surface:** All four clear ≥3:1 and remain distinct from the dark categorical slots.

**Collision rule:** When a series *means* good/bad (error rate, pass/fail, uptime), it wears status tokens. When it's just "series 4," it wears categorical. Never both in one chart.

## Texture fill (the accessibility channel)

One hand-drawn **"Lines"** fill, used at **45° and its 135° mirror only** (never horizontal/vertical). Inked tone-on-tone (a darker step of the fill's own ramp). On value scales, it is *ordered* (rotation steps with magnitude; arm angle carries the diverging sign).

Triggered by:
- An accessibility setting toggle
- Print export
- `forced-colors` media query

Never on by default. Dense angled fields are a vestibular risk and read as noise.

## Chart chrome & ink

| Role | Light | Dark |
|---|---|---|
| Chart surface | `#fcfcfb` | `#1a1a19` |
| Page plane (background) | `#f9f9f7` | `#0d0d0d` |
| Primary ink (text) | `#0b0b0b` | `#ffffff` |
| Secondary ink (labels) | `#52514e` | `#c3c2b7` |
| Muted (axis/hints) | `#898781` | `#898781` |
| Gridline (hairline, 1px) | `#e1e0d9` | `#2c2c2a` |
| Baseline / axis | `#c3c2b7` | `#383835` |
| Delta ↑ good (success text) | `#006300` | `#0ca30c` |
| Border (hairline ring, 10% alpha) | `rgba(11,11,11,0.10)` | `rgba(255,255,255,0.10)` |

## Filter controls

Filters are standard UI, not chart components — build them with HTML form controls styled to match the chart chrome. Dataviz adds only composition rules (see `interaction.md`):

- **One row, above the charts** — filters sit in a single left-aligned row
- **Date range first** — presets (today, last 7/30/90 days) with 16px bold check for selection
- **Hover is a ghost wash** — never competes with selection
- **Custom range behind a hairline** in the footer

## Typeface & figures

Everything — including the hero figure — stays in the system sans: `system-ui, -apple-system, "Segoe UI", sans-serif`. No display or serif face anywhere.

- **Large standalone numbers** (hero figure, stat-tile value): proportional figures (default `font-variant-numeric`)
- **Columns that must align vertically** (table rows, axis ticks): `font-variant-numeric: tabular-nums`

Substitute your brand's UI sans here if needed. The logic stays the same — one sans for everything, tabular only where it's needed for alignment.
