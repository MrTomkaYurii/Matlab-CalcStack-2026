# Two-Point Polarization-Correlation Framework (august2026)

Modular MATLAB pipeline for two-point Mueller-matrix parameters `f_ik`
(module + argument, 16 elements) of a holographically reconstructed complex
field of birefringent tissue. Config-driven: to extend, you normally only
edit `config/cfg_TwoPoint.m` and/or drop in one new module.

**This is a fork of `july2026`.** `july2026` stays frozen (old BMP-intensity
data format, `source='real'`). `august2026` consumes the NEW data format:
already-reconstructed COMPLEX fields (`source='mat'`), and adds the
phase-windowing stage described below — all further work happens here.

## Run

```matlab
cd C:\Users\Yurii\Documents\MATLAB\august2026
run_TwoPoint_Pipeline            % uses config/cfg_TwoPoint.m
```

The default config processes ALL samples in `CFG.samples` × ALL examples in
`CFG.paths.examples` × ALL of `CFG.phase.numWindows` phase windows × ALL
algorithms in `CFG.algorithms` — fully automatic, folders created as needed.

To run just one slice without touching the permanent config, pass an
override struct:

```matlab
CFG = cfg_TwoPoint();
CFG.samples          = {'Серце'};
CFG.paths.examples   = {'2'};
CFG.phase.numWindows = 3;          % quick partial run
CFG.algorithms       = {'orthogonal'};
run_TwoPoint_Pipeline(CFG);
```

Two more independent entry points (read-only, never recompute anything —
safe to run any time, even mid-way through a long `run_TwoPoint_Pipeline`):

```matlab
run_TwoPoint_CollectForHorsky    % consolidate result.mat -> one .mat/sample for sharing
run_TwoPoint_GIF_Demo            % build the two explainer GIFs (small synthetic sample)
```

## Data source

```
C:\August 2026-Results\rez_cs\<Зразок>\<Приклад>\mat\ex_<state>.mat, ey_<state>.mat
```
`<Зразок>` ∈ `{Мозг, Мяз живота, Серце}`, `<Приклад>` ∈ `{1,2,3}`,
`<state>` ∈ `{0,45,90,135,liv,prav}`. Each `.mat` holds exactly ONE complex
`N×N double` variable (name varies, e.g. `cs1_crop` — `tp_load_mat.m` reads
whichever single variable is present). Unlike the old BMP format, amplitude
and phase come straight from the complex number — no `sqrt(I)` or
Stokes-vector reconstruction needed: `|Ex|=|ex|`, `|Ey|=|ey|`,
`delta = angle(ey) - angle(ex)`.

**Known data-quality issue** (checked 2026-08-23, `explore_mat_data.m`-style
scan): `ex_90.mat` and/or `ey_0.mat` are all-zero / real (not complex) for
**Мозг/1, Мозг/2, Мозг/3, Серце/1** — these 4 of 9 sample/example
combinations cannot be computed until re-reconstructed on the source side.
**Мяз живота/1,2,3** and **Серце/2,3** (5 of 9) are clean. The pipeline logs
`[skip sample]`/`[fail]` for the broken ones and continues with the rest —
it does not silently produce wrong numbers.

## Phase windows (Stage 1 of the "Юра Томка" ТЗ)

Before the two-point scan, the field is phase-gated: for each pixel, a
single reference phase `delta_ref = angle(Ey) - angle(Ex)` of illumination
`CFG.phase.refPol` (default `inRC`, right-circular) is computed once, normalized to
`[0, 2*pi)`. `CFG.phase.numWindows` (8) windows `[0, U_k]` are then applied,
`U_k` spaced in even `0.25π` steps from `CFG.phase.upperMax` (2.00π, k=1 —
effectively no filter) down to `CFG.phase.upperMin` (0.25π, k=8 —
narrowest): `2.00π, 1.75π, 1.50π, 1.25π, 1.00π, 0.75π, 0.50π, 0.25π` — round
bounds, not arbitrary decimals. Pixels outside the window become `NaN` in
`Ex`,`Ey` of **all** illuminations (one shared mask) —
`core/tp_phase_window.m`. Downstream formulas (`tp_fik_pair`) are already
NaN-safe, so a point pair only contributes if **both** points survive the
mask; no other code needed to change.

`inRC` (right-circular) is the reference channel by literature precedent,
not an arbitrary pick: the same research group's papers on two-point Stokes
correlometry / Mueller matrix polarization interferometry of biological
tissue consistently illuminate with **circular** polarization specifically
because it is **azimuthally invariant** — measurements don't depend on the
tissue/instrument's rotational alignment, unlike a fixed linear angle
(0°/45°/90°) would be. Narrowing the phase window itself is also literature-
grounded, not just an exercise: reducing δ's range progressively isolates
the field's single-scattered component from multiply-scattered light.

Sources: [Two-point Stokes vector diagnostic approach for characterization
of optically anisotropic biological tissues](https://iopscience.iop.org/article/10.1088/1361-6463/ab9571),
[Mueller matrix polarization interferometry of optically anisotropic
architectonics of biological tissue object fields](https://www.frontiersin.org/journals/physics/articles/10.3389/fphy.2023.1302254/full)

Each window gets its own output folder, named with the bound baked in for
readability (`core/tp_phase_folder_name.m`):
```
phase_01_[0-2.00pi]  ...  phase_08_[0-0.25pi]
```
Set `CFG.phase.enable = false` to skip windowing entirely and compute once
on the raw field (folders collapse back to the pre-phase layout).

## Algorithms

- **`orthogonal`** (`core/algo/orthogonal/tp_algo_orthogonal.m`) — for each first point r1,
  the second point r2 is `r1+(d,0)` (→ `OX`) or `r1+(0,d)` (→ `OY`), no
  averaging, one value per pixel. `CFG.ortho.steps` (array, e.g.
  `[1 2 4 8 16 32]`) sets the separation(s) d; `CFG.ortho.directions`
  narrows to `{'OX'}`/`{'OY'}`. One `result.mat` is written per
  direction+step (`orthogonal/OX/step_<d>/result.mat`, variable `Rd`,
  sliced from the full in-memory result) — not one combined file — so it
  matches `generalized`'s per-step layout and lets tools iterate all of
  them the same way regardless of algorithm.
- **`generalized`** (`core/algo/generalized/tp_algo_generalized.m`) — full 2D separation-
  vector scan (Δx,Δy), averaged over all first points (module: arithmetic;
  argument: circular). This **is** the "combined XY map" the ТЗ asks for —
  no separate merge step needed, it already covers the whole 2D plane.
  `CFG.gen.steps` (array, e.g. `[1 2 4 8 16 32]`) sets the grid spacing;
  one `result.mat` per step (`generalized/step_<d>/result.mat`, variable `R`).
- **`polar`** (`core/algo/polar/tp_algo_polar.m`) — for each first point r1, the
  second point is scanned around it on a **polar grid of angles**:
  θ = `0 : CFG.polar.angleStep : CFG.polar.angleMax−angleStep` deg, radius
  `CFG.polar.radii` px (default `[1]`). All directions are merged into one map
  `PERP` by a **complex SUM (no division)** — `f⊥(r1) = Σ_θ f_ik(r1, r1+ρ·(cosθ,sinθ))`
  — the complex add is done *before* modulus/argument (doc "…с единой картой",
  §7); a second point outside the frame / in a phase-window NaN drops that
  direction from the sum for that pixel (`R.params.validCount` records how many
  contributed). Also stores axis maps `OX` (θ=0) and `OY` (θ=90°). Per-angle
  maps `|f_ik(θ)|` + the sum are dumped as one subplot montage per
  `CFG.polar.montageElements` under `polar/PERP/step_<ρ>/angle_montage/`.
  One `result.mat` per direction+step, like `orthogonal` (variable `Rd`).
  Positioned between `orthogonal` (2 directions) and `generalized` (all vectors).
- **`XY`** (`core/algo/XY/tp_algo_XY.m`) — the **unified cross map** from doc
  "…с единой картой" §7: after the horizontal and vertical results are accumulated
  separately, they are **combined**. Here the combine is a **complex SUM `OX + OY`
  (no averaging)** — complex add before modulus/argument. It does **not** recompute
  `f_ik` or re-save `OX`/`OY`: it reads the already-saved
  `orthogonal/OX/step_<d>/result.mat` + `orthogonal/OY/step_<d>/result.mat` and
  sums them, so `orthogonal` must be in `CFG.algorithms` (processed first) with both
  `CFG.ortho.directions`. One map per step `d` in `CFG.ortho.steps` →
  `XY/step_<d>/result.mat` (variable `R`, like `generalized`).
  `R.params.validCount` records how many arms (0–2) contributed per pixel.

## Visualization (per element f_ik, per direction)

| # | Module | What |
|---|--------|------|
| — | `viz_overview.m` | 4×4 grid, all 16 f_ik at once (module, argument) |
| **Block 1** | `viz_block1_summary.m` | ТЗ block: module map + argument map, histograms below, ACF cross-section (zoomed + HWHM) below that — ONE figure, 3×2. Saved as `_block1_<fXX>_<cmap>.png` (leading `_` sorts it first in the folder) |
| **Block 2** | `viz_skeleton.m` | ТЗ block: 2D skeleton (WTMM maxima) + histogram of maxima distribution, module + argument. Saved as `_block2_<fXX>_<cmap>.png` |
| **Block 3** | `viz_block3_contours.m` | ТЗ block: 2D contour + 3D contour, module + argument (2×2). Saved as `_block3_<fXX>_<cmap>.png` |
| **Block 4** | `viz_multifractal.m` | Our own addition (not in the ТЗ): full WTMM multifractal computation chain — partition function (+ fit lines) → τ(q) (+ R²) → h(q) → f(h) spectrum, 4×2. Saved as `_block4_spectrum_<fXX>.png` (single file, no colormap — line plots only) |
| **Block 5** | `viz_multifractal_dimensions.m` | Our own addition: generalized dimensions D(q) with D0/D1/D2 marked + monotonicity check, and f(h) again with left/right half-width and asymmetry. Saved as `_block5_dimensions_<fXX>.png` |
| 1 | `viz_maps_hist.m` | module map, argument map, their histograms (2×2) — standalone version of Block 1's top two rows |
| 2 | `viz_sections.m` | contour maps + 3D surfaces (2×2); contour levels are labeled in a column at the panel edge, each with a thin leader line + dot pointing at its actual line (not color-matched — plain black text reads better than trying to match close colormap shades); lines lightly smoothed; label format adapts to magnitude (`%.3g`, was a fixed `%.2f` that printed "0.00" for every level on real |f_ik|~1e-6 data) |
| 2b| `viz_contour3d.m` | contour lines in 3D (now smoothed the same way as the 2D panel — previously wasn't, and fell apart into noise on real data), same leader-line labeling scheme in 3D (at each label's own z-height) |
| 3 | `viz_wavelet.m` | CWT scalogram W(a,b) of a 1D profile, module + argument, with the **cone of influence** now shaded (coefficients beyond it, near the profile edges, are unreliable) and **highlighted scales derived from the measured ACF half-width** (0.5×/1×/2× HWHM) instead of fixed synthetic-era numbers (10, 50) |
| 4A| `viz_acf_psd.m` | 2D ACF + 2D PSD |
| 4B| `viz_acf_cuts.m` | 1D ACF cross-sections (OX,OY) **zoomed near the peak** (auto-ranged to where ACF > 0.1×peak) with **HWHM markers** + a **two-segment log-log PSD fit** (not one global slope — real data usually has a "knee"; the high-frequency segment is auto-flagged as noise floor and shaded when its slope is ~flat) |
| 5 | `viz_skeleton.m` | (= Block 2 content, see above); WTMM maxima now excluded outside the cone of influence (same fix as (3)) — this feeds real numbers, not just a picture, so the exclusion matters more here than cosmetically |
| 6 | `viz_level_bands.m` | concentration near N levels — short "Level j/N" titles (long ones used to overlap across 4 narrow columns) with details in an inline box, one consistent histogram color (was a rainbow per level, looked noisy) |
| — | `viz_stats_table.m` | **text file**, not a figure: mean/std/skew/kurt table for module & argument, one file per element (`<fXX>_stats.txt`, same folder as its figures) |
| — | `viz_phase_mask.m` | **per phase window**, once (not per element): reference-phase map + binary kept/excluded mask, so a narrow window's pixel loss is visible at a glance |
| — | `tp_phase_trend.m` | **per sample/example**, once all windows are done: 4×4 grid of mean±std vs. window index, for every f_ik — shows how each element evolves as the phase window narrows |

Blocks 1–5 are ADDITIONAL to the standalone representations (1)/(2)/(2b)/(3)/(5)
— nothing was removed, the block figures just also present the same
content pre-assembled (Blocks 1–3 the way the ТЗ specifies; Blocks 4–5 are
our own multifractal add-on, see below), easy to spot first (`_` prefix)
in a folder full of per-representation files.

### Multifractal analysis (Blocks 4–5, `core/tp_multifractal.m`)

WTMM (wavelet transform modulus maxima) formalism: the partition function
is built from the SAME local maxima of |W(a,b)| as the Block 2 skeleton
(not raw pixel values — only the wavelet's local maxima carry a rigorous
link between their cross-scale amplitude decay and the local Hölder
exponent). Normalized per scale (Σp=1) so `D(q)=τ(q)/(q-1)` behaves
smoothly through q=1 — an earlier unnormalized version produced a sawtooth
discontinuity there. This is a **simplified** WTMM (partition function over
all per-scale maxima, no cross-scale maxima-line chaining as in the full
classical method) — an adequate overview for us; the full analysis is
M. Horsky's, on the raw distributions we hand off
(`run_TwoPoint_CollectForHorsky.m`). A companion Word document explaining
every block with embedded example figures and the full theory writeup was
generated for this — ask for it to be regenerated if it's gone stale.

ACF/PSD are computed ONCE per element (`tp_visualize.m`, `meta.acfData`) and
shared between 4A/4B. CWT is computed once and shared between 3/5. Moments
(mean/std/skew/kurt) use a single shared formula (`core/tp_moments.m`) so
the numbers on histogram overlays and in `_stats.txt` always match —
circular moments for argument (phase), linear for module.

## Output tree

```
<saveRoot>\<Зразок>\<Приклад>\
  phase_01_[0-2.00pi]\
    phase_info.txt              window bounds + % pixels kept
    phase_mask.png               reference-phase map + kept/excluded mask
    orthogonal\
      00_overview_modules_<cmap>.png, 00_overview_arguments_<cmap>.png   (per dir, see below)
      OX\step_1\
        result.mat                 ONE file per direction+step (Rd, sliced from the full R)
        <fXX>\<fXX>_maps_hist_<cmap>.png, ..._stats.txt, ...
      OX\step_2\ ... OX\step_32\    (one result.mat per CFG.ortho.steps entry)
      OY\step_1\ ... OY\step_32\    (same, for OY)
    generalized\
      step_1\result.mat, <fXX>\...
      step_2\ ... step_32\          (one result.mat per CFG.gen.steps entry)
  phase_02_[0-1.75pi]\
    ...
  ...
  phase_08_[0-0.25pi]\
    ...
  phase_trend\<algorithm>\<dir>\trend_modules.png, trend_arguments.png
```

`<saveRoot>` = `CFG.paths.saveRoot` (`C:\August 2026-Results\Двот. елем.
матриці Мюллера`). `cmap` = `jet | gray`. Setting `CFG.phase.enable=false`
removes the `phase_XX` level (algorithm folders sit directly under
`<Приклад>`), matching the pre-phase-window layout.

## Sharing data separately from the figures (Stage 3 of the ТЗ)

`core/tp_collect_sample_for_horsky.m` reads whatever `result.mat` already
exist on disk for ONE sample (never recomputes), and writes a SEPARATE
`.mat` per example × algorithm (examples 1/2/3 are never merged into one
file) into `CFG.paths.horskyRoot` (`C:\August 2026-Results\MOD-ARGS-MM-Горському`)
— module/argument distributions only, no PNGs, for
handing off to M. Horsky's multifractal-spectrum analysis:

```
<Зразок>_<Приклад>_orthogonal.mat    (variable inside: orthogonal)
<Зразок>_<Приклад>_generalized.mat   (variable inside: generalized)
<Зразок>_<Приклад>_polar.mat         (variable inside: polar)
<Зразок>_<Приклад>_XY.mat            (variable inside: XY)

orthogonal.phase_0to<D>deg.<OX_step_D|OY_step_D>.<fXX>.mod/.arg
generalized.phase_0to<D>deg.step_<D>.<fXX>.mod/.arg
polar.phase_0to<D>deg.<PERP_step_D|OX_step_D|OY_step_D>.<fXX>.mod/.arg
polar.phase_0to<D>deg.PERP_step_D.validCount   (extra: N directions summed per pixel)
XY.phase_0to<D>deg.step_<D>.<fXX>.mod/.arg     (unified OX+OY, no averaging)
XY.phase_0to<D>deg.step_<D>.validCount         (extra: N arms (0-2) summed per pixel)
```

`D` in `phase_0to<D>deg` is the window's upper bound in degrees (whole
numbers, no decimals): `phase_0to360deg` (barely filtered) down to
`phase_0to45deg` (narrowest, step 45° = 0.25π). `D` in `step_<D>` is the
pixel distance (1, 2, 4, 8, 16, 32). For `polar`, `PERP_step_D` is the
single unified map (complex sum `Σ_θ f` over the polar angle scan, no
division), `OX/OY_step_D` its θ=0 / θ=90° axial slices, and
`PERP_step_D.validCount` is the per-pixel count of directions that actually
entered the sum (`nAngles` in the interior, fewer near the frame edge) —
forwarded so the ratio scale can be normalised downstream if needed. For `XY`,
`step_D` is the unified `OX + OY` (no averaging), with its own `validCount`
(0–2 arms per pixel); `OX`/`OY` themselves are in the `orthogonal` file, not
duplicated here. Which algorithms get collected is `CFG.horsky.algorithms`
(default: all four).

**Runs automatically** — `run_TwoPoint_Pipeline.m` calls it the moment a
sample (all its examples) finishes computing, so each sample's data is
handed off progressively as it becomes ready ("по мірі обчислення
надсилати", per the ТЗ), no manual step needed. `run_TwoPoint_
CollectForHorsky.m` is the same logic as a standalone, independent
entry point — safe to (re-)run any time, including mid-way through a long
computation, e.g. to force a refresh or collect samples computed in an
earlier session. A `README.txt` describing the structure is written
alongside the `.mat` files.

## Project layout

```
run_TwoPoint_Pipeline.m          main entry: sample x example x phase-window x algorithm loops;
                                  auto-collects each sample for Horsky as soon as it finishes
run_TwoPoint_CollectForHorsky.m  standalone/independent re-run of the same Horsky collection
run_TwoPoint_GIF_Demo.m          two annotated demo GIFs (small synthetic sample)
explore_mat_data.m               standalone diagnostic: inspect a folder of ex_*/ey_*.mat files
config/cfg_TwoPoint.m            ALL parameters -> struct CFG
core/
  tp_load_images.m               dispatch: source='mat'|'synthetic' (source='real' kept for parity, unused here)
  tp_load_mat.m                  read ex_*/ey_*.mat (tolerant to several folder-nesting variants)
  tp_phase_window.m              apply phase window k -> masked IMG + info (mask, deltaRef, keptFrac)
  tp_phase_window_bounds.m       U_k values for k=1..numWindows
  tp_phase_folder_name.m         canonical 'phase_KK_[0-X.XXpi]' folder name (single source of truth)
  tp_phase_trend.m               post-hoc: mean/std vs phase window, one 4x4 figure per algorithm+dir
  tp_collect_sample_for_horsky.m consolidate ONE sample's result.mat -> <Зразок>.mat (read-only)
  tp_slice.m                     generic nested-struct slicer (any field-name shape)
  tp_fik_pair.m                  formulas (1),(6)-(13),(sect.4) -> 16 complex f_ik, from complex Ex,Ey directly
  tp_base_result.m               empty canonical result struct
  algo/orthogonal/
    tp_algo_orthogonal.m         OX / OY maps, one call computes ALL CFG.ortho.steps
    tp_slice_result_dir.m        slice full R -> one-direction Rd (per-dir result.mat)
  algo/generalized/
    tp_algo_generalized.m        ONE pseudo-ACF (2D) diagram per call, for a single step
  algo/polar/
    tp_algo_polar.m              polar angle scan -> PERP (Sum_theta complex, no /N) + OX/OY + angle montage
  algo/XY/
    tp_algo_XY.m                 unified map: reads orthogonal OX+OY, sums them (complex, no averaging), per step d
  tp_validate.m                  quality control (skip degenerate elements)
  tp_visualize.m                 dispatcher: per dir -> overview + per-element figures
  tp_check_config.m              fail-fast CFG validation
  tp_acf_psd.m                   shared 2D ACF/PSD (fast | direct)
  tp_moments.m                   shared mean/std/skew/kurt (linear + circular)
  tp_smooth2.m                   NaN-safe Gaussian smoothing, display-only (contour lines)
  tp_multifractal.m              WTMM multifractal spectrum (Blocks 4-5): partition fn -> tau(q) -> h(q) -> f(h) -> D(q)
  tp_piecewise_loglog_fit.m      two-segment log-log fit + noise-floor detection (viz_acf_cuts.m PSD panel)
  tp_contour_levels.m, tp_format_level.m, tp_level_color.m   shared by all 3 contour-drawing viz modules
  tp_assert.m
io/tp_save_figure.m               folder routing + exportgraphics (filename sanitizer keeps a leading '_' —
                                  matlab.lang.makeValidName would silently prepend 'x' and break block sort order)
viz/
  viz_style.m                    shared light-theme styling / fonts
  viz_block1_summary.m, viz_block3_contours.m                (Blocks 1, 3)
  viz_multifractal.m, viz_multifractal_dimensions.m          (Blocks 4, 5)
  viz_overview.m, viz_maps_hist.m, viz_sections.m, viz_contour3d.m,
  viz_wavelet.m, viz_acf_psd.m, viz_acf_cuts.m, viz_skeleton.m,
  viz_level_bands.m, viz_stats_table.m, viz_phase_mask.m    (see table above)
simulation/
  tp_sim_speckle_BT.m            physical BT simulator — kept ONLY because gif/ demo needs it
                                  (source='synthetic' otherwise unused; stage helpers removed, see below)
gif/
  tp_gif_writeframe.m, tp_gif_orthogonal.m, tp_gif_generalized.m
```

**Removed from this copy** (were july2026-specific, not needed here — still
exist untouched in `july2026` if ever needed again):
`old/` (legacy reference scripts — formulas already verified & ported into
`tp_fik_pair.m`), `test/` + `run_TwoPoint_Pipeline_test.m` (diagnostic
step-by-step pipeline, hardcoded to the old BMP struct shape, never
adapted), `run_TwoPoint_Simulation_analysis.m` + `simulation/tp_sim_stage*`
+ `tp_sim_preview.m` (synthetic-data diagnostics — `source='synthetic'` is
not the active workflow here), `tp_gen_synthetic.m` (dead code, superseded
by `tp_sim_speckle_BT.m` well before this fork).

## Doc → code mapping

| Spec | Implemented in |
|------|----------------|
| Матрицы Мюллера (1),(6)-(13),(sect.4) — amplitude/phase now read directly from complex Ex,Ey | `core/tp_fik_pair.m` |
| Ортогонально-направленный (OX и OY, раздельно) | `core/algo/orthogonal/tp_algo_orthogonal.m` |
| Ортогонально-направленный «с единой картой» (полярная сетка углов → PERP комплексной суммой Σ_θ, без деления) | `core/algo/polar/tp_algo_polar.m` |
| Ортогонально-направленный «с единой картой» §7 — объединение `OX+OY` в одну карту, **без усреднения** §6–7 (читает orthogonal-результат) | `core/algo/XY/tp_algo_XY.m` |
| Обобщённый (усреднение по (Δx,Δy), круговое для arg) = "об'єднана мапа XY" | `core/algo/generalized/tp_algo_generalized.m` |
| Етап 1: фазові вибірки [0,2π]→[0,0.25π] (крок 0.25π, 8 вікон) | `core/tp_phase_window*.m`, wired into `run_TwoPoint_Pipeline.m` |
| Етап 2.1: модулі/аргументи/гістограми/АКФ (з півшириною)/скелетон+гістограма екстремумів/статистичні моменти(таблиці)/контури | see visualization table above |
| Етап 2.2: OX, OY, XY послідовно | `CFG.algorithms = {'orthogonal','generalized'}` |
| Етап 3: передача розподілів для мультифрактального аналізу | `run_TwoPoint_CollectForHorsky.m` |

## Extension points (append, don't rewrite)

- **New sample** → add its folder name (matching `rez_cs\<name>`) to `CFG.samples`.
- **New algorithm** → add `core/algo/<name>/tp_algo_<name>.m` returning a `tp_base_result`
  struct; add a branch in `run_TwoPoint_Pipeline`'s `runAlgorithms` and the
  name to `CFG.algorithms`.
- **New representation** → add `viz/viz_<name>.m(D, meta, ctx, CFG)`; call it
  from `tp_visualize` behind a `CFG.viz.<name>` flag (via `runViz`).
- **Phase-window count/range** → `CFG.phase.numWindows` / `.upperMax` /
  `.upperMin` / `.refPol` — everything downstream (folder names, trend plot,
  Horsky export) reads these, nothing else to touch.

## Robustness & validation

- **Fail-fast config check:** `run_TwoPoint_Pipeline` calls
  `tp_check_config(CFG)` first — bad config (missing `matRoot`, invalid
  `rcSource`, bad phase-window bounds, etc.) is reported early with a clear
  message, not deep inside a long computation.
- **Boundary error handling:** every sample/example, every phase window,
  every algorithm/step, every figure module is wrapped in try/catch — one
  failure logs `[fail]`/`[viz fail]`/`[skip sample]` and the run continues.
- **QC:** border pixels (or phase-masked-out pixels) with no valid partner
  stay `NaN`; `tp_validate` drops maps that are all-NaN, mostly-NaN
  (`CFG.qc.maxNaNfrac`), or near-constant (`CFG.qc.minStd`) — not saved, not
  plotted. A very narrow phase window can legitimately drop an element this
  way (see `phase_mask.png` / `phase_info.txt` for the retained fraction).
- **Figure rendering is parallelized** (`CFG.viz.parallel`, default `true`):
  `tp_visualize`'s per-element loop runs as `parfor`, each worker receiving
  only its own element's data (`Dlist{v}`), never the full result struct —
  avoids the `Out of Memory during deserialization` broadcast bug found
  earlier (any dot-indexed reference to `R` inside the loop body forces
  MATLAB to ship the ENTIRE struct to every worker).
- Requires Wavelet Toolbox (representations 3, 5) and Image Processing
  Toolbox (used by the GIF demo).

## Known open items

- 4 of 9 sample/example combinations have corrupted source `.mat` files
  (see "Known data-quality issue" above) — needs re-reconstruction upstream.

## Resolved (previously open, now literature-backed — see "Phase windows" above)

- `CFG.mat.rcSource = 'prav'` (right-circular) and `CFG.phase.refPol =
  'inRC'` — both confirmed against the source research group's published
  methodology (right-circular illumination for azimuthal invariance), not
  arbitrary defaults.
