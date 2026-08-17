# Color formula

Color is not hand-picked. Every chart color does exactly one of four jobs, and a palette is legal only if it passes six measurable checks. The checks are the product — they determine what makes a palette safe to change, and they let the same method work on any design system's ramps.

## The four jobs

| Job | What it encodes | Structure |
|---|---|---|
| **Categorical** | Identity — which series | 8 hues, fixed order, assigned in sequence, never cycled |
| **Sequential** | Magnitude — how much | One hue, steps 100→700, light→dark; anchor flips in dark mode |
| **Diverging** | Polarity — which side of a baseline | Two hues + a neutral gray midpoint; equal steps per arm |
| **Status** | State — good/warning/serious/critical | Small fixed scale, reserved meaning, always paired with icon + label |

**Categorical vs ordinal:** If swapping the category order would change meaning (funnel stages, size tiers S/M/L, age bands, cohort buckets), it is **ordinal** and takes a one-hue ramp so the reader sees the order in the color. If swapping would not (product names, teams, regions, endpoints), it is **nominal categorical** and each bar wears the same slot-1 hue (one series, no legend box), or slots 1..N when there are N separate series. **Never color nominal bars by their value** — that double-encodes what bar length already shows and spends the only free channel on redundant information.

## The six checks

Every categorical palette — current or proposed — must pass all six. These checks compute color science; do not eyeball them.

### 1. Fixed hue anchors (structural)

Eight hue families in a fixed order. The order is the CVD-safety mechanism; it never changes. This is a structural rule enforced at design time, not measured by the validator. It is what lets the same palette work under CVD simulation.

### 2. Lightness band (OKLCH L)

Each slot must fall within the mode's band:
- **Light mode:** OKLCH L ≈ 0.43–0.77
- **Dark mode:** OKLCH L ≈ 0.48–0.67

Lighter than the lower bound and the slot reads as background, not a mark. Darker than the upper bound (in light mode) and it becomes too heavy; in dark mode, it disappears into the surface. The validator reports any slot outside the band.

### 3. Chroma floor (OKLCH C ≥ ~0.10)

Below 0.10 chroma, a hue reads as gray and stops doing identity work. Every slot must clear this floor or the whole slot fails as categorical. The validator reports any slot below the floor.

### 4. CVD separation (OKLab ΔE, ×100 scale)

Color-blind readers must tell adjacent series apart. The validator simulates protan and deutan vision using the Machado–Oliveira–Fernandes (2009) model at severity 1.0 — the model is part of the standard, not an implementation detail. Swapping simulators changes the boundaries and would require recalibrating every threshold.

- **Target:** ≥ 8 ΔE between adjacent slots (stacks, bars, lines where only neighbors touch)
- **Floor:** ≥ 6 ΔE (legal only with secondary encoding: direct labels, gaps, or texture)
- **Hard failure:** < 6 ΔE

For all-pairs forms (scatter, bubble, choropleth, small multiples where any two marks can sit side by side), the validator checks every pair, not just neighbors. This is strictly harder and caps the series count — the reference palette validates all-pairs for the first three slots only. Past three, fold to "Other" or facet.

The validator also reports the tritan confusion (full-spectrum CVD) for reference; tritan is much rarer and less constraining.

### 4b. Normal-vision floor (OKLab ΔE ≥ 15, unsimulated)

Full-color readers must also tell neighbors apart. The worst-case pair on the active pairlist (adjacent or all-pairs) must have ΔE ≥ 15 in unsimulated vision — no secondary encoding excuse, no exceptions. A pair below 15 is hard to distinguish even with perfect color vision and fails the chart. The validator flags the worst pair and its exact ΔE.

### 5. Contrast vs surface (WCAG ≥ 3:1)

Every mark must clear 3:1 contrast against the chart surface:
- **Light surface:** mark hex vs light background
- **Dark surface:** mark hex vs dark background

Sub-3:1 is conditional relief — legal only if you ship a visible direct label or the table view (not the tooltip, which can disappear). If you ship the sub-3:1 fill alone, that is inaccessible and fails the chart. The validator flags any slot below 3:1 and marks it as requiring relief.

### 6. Documented palette only (structural)

Every slot is a hex from an instance file (`palette.md` or the system's equivalent) — no eyeballed values, no generated colors. When you snap a customer's ramps to passing values, every output is documented in their own `palette.md`; you never commit generated or ad-hoc hex. This is what lets a palette change without breaking the method.

## Run the checks — never eyeball them

The validator is a plain Node.js script. Feed it a comma-separated hex list and the mode:

```
node scripts/validate_palette.js "#2a78d6,#eb6834,#1baf7a,#eda100,#e87ba4,#008300,#4a3aa7,#e34948" --mode light
```

Or, for dark mode with a custom surface:

```
node scripts/validate_palette.js "#3987e5,#d95926,..." --mode dark --surface "#1a1a19"
```

For **ordinal** ramps (discrete ordered marks — funnel stages, tiers), pass `--ordinal`:

```
node scripts/validate_palette.js "#86b6ef,#5598e7,#256abf,#104281" --ordinal
```

The validator reports each computable check (2–5) with **PASS** / **WARN** / **FAIL** plus the worst-case color pair. Exit code 0 means no hard failures (WARNs still exit 0 and require secondary encoding). Exit code 1 means at least one FAIL — fix it before shipping.

Exit status:
- **Exit 0:** All checks pass, or WARNs only (CVD floor 6–8 with secondary encoding, contrast sub-3:1 with relief)
- **Exit 1:** Any FAIL (normal-vision floor below 15, CVD floor below 6, lightness out of band, chroma below floor, or invalid palette)

## Interpreting the report

| Result | What it means | What to do |
|---|---|---|
| **Lightness band — PASS** | All slots within the mode's band | Ship as-is. |
| **Lightness band — FAIL** | One or more slots outside the band | Re-step the slot ±L (hold hue, shift lightness). Re-run. |
| **Chroma floor — PASS** | All slots ≥ 0.10 chroma | Ship as-is. |
| **Chroma floor — FAIL** | One or more slots below floor | Nudge the slot +0.01 C (shift toward the hue's pure point). Re-run. |
| **CVD separation — PASS** | All pairs ≥ 8 ΔE | Ship as-is. |
| **CVD separation — WARN** | Some pair 6–8 ΔE | Legal only with secondary encoding (direct labels, gaps, texture). Add it and ship. |
| **CVD separation — FAIL** | Some pair < 6 ΔE | Re-step one of the pair ±L (hold hue). Re-order slots if possible. Re-run. |
| **Normal-vision floor — PASS** | Worst pair ≥ 15 ΔE | Ship as-is. |
| **Normal-vision floor — FAIL** | Worst pair < 15 ΔE | Re-step one of the pair ±L. This is a hard gate; secondary encoding does not excuse it. Re-run. |
| **Contrast vs surface — PASS** | All marks ≥ 3:1 | Ship as-is. |
| **Contrast vs surface — WARN** | Some mark 3:1 or below | Legal only if you ship visible direct labels or the table view. Add one and ship. |

## Snap-to-passing (for custom ramps)

When you have a customer's ramps and a desired slot order, use this procedure to snap the values to passing:

1. For each slot, pick the step whose OKLCH L sits in the mode's band and C ≥ floor.
2. Run the validator. Note any adjacent pair below the ΔE 8 target.
3. For each below-target pair, nudge one slot ±1 step in lightness (hold its hue, move L). Re-run.
4. Repeat step 3 until the worst adjacent pair clears the 8 ΔE target.
5. Verify the normal-vision floor (≥ 15) and contrast (≥ 3:1). If any fail, re-step and re-run.
6. Lock the output in your own `palette.md` — every slot is now documented hex, never regenerated.

The function is preserved; the customer's hues are kept. You've only re-stepped the lightness to pass the gates.

## Themes (slot order variants)

The slot **order** is a separable, named choice — a *theme* — on the same hues and the same checks. Each design system names a default order and any alternates. Swapping themes tunes mood without touching method.

**Deriving an order when a system has no theme yet:** Don't guess. Enumerate candidate orderings of the system's hues, run the validator on each, and pick the one that maximizes the *minimum adjacent* CVD ΔE in both modes. (Seeding from a known-good order by hue-family analogy, then optimizing, is a practical shortcut — the reference palette in `palette.md` came from exactly that enumeration, as one of the tied top orders, picked among them for its opening colors.)

## Status is fixed

Status never follows the theme — it is a small fixed scale (good → warning → serious → critical) with reserved meaning, on steps deliberately distinct from the categorical slots so a status color never impersonates a series. Status is always paired with an icon + label (on a light surface, warning and serious sit below 3:1 by design — the pairing is the mitigation).

**Collision rule:** When a series *means* good/bad (error rate, pass/fail, uptime), it wears status tokens. When it's just "series 4," it wears categorical. Never both in one chart.

## Scope — what the validator measures and doesn't

The validator measures **categorical** palettes (series identity). It does **not** judge:
- A lone status or text color → run a WCAG *text*-contrast check (4.5:1 normal, 3:1 large); the validator exports `contrast(a, b)` for this
- A sequential ramp → the check is lightness monotonicity across the steps, not adjacency CVD; running the categorical validator on a sequential ramp **will FAIL by design** (it spans the band; steps sit close), which is expected and not a real failure; don't "fix" a good ramp to satisfy it
- An ordinal ramp (ordered categories) → use `--ordinal` flag; the validator switches to ramp-specific checks (monotone L, adjacent ΔL ≥ 0.06, light-end contrast ≥ 2:1, single hue)
