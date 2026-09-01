# Two-Point Polarization-Correlation Framework

Modular MATLAB pipeline for two-point Mueller-matrix parameters `f_ik` of a
holographically reconstructed speckle field. Config-driven: to extend, you
normally only edit `config/cfg_TwoPoint.m` and/or drop in one new module.

## Run

```matlab
cd C:\Users\Yurii\Documents\MATLAB\july2026
run_TwoPoint_Pipeline            % uses config/cfg_TwoPoint.m
```

The default config (`CFG.source = 'real'`) processes ALL real samples under
`CFG.paths.readRoot` × ALL sub-folders in `CFG.paths.examples` automatically —
e.g. 10 tissue types × `{'zrazok_1','zrazok_2'}` = 20 independent runs, each
saved to its own nested folder (created automatically, no manual setup).

To run on the synthetic demo instead (no real data needed), set
`CFG.source = 'synthetic'` and `CFG.samples = {'Demo'}`.

To run just one specific sample/algorithm/step without touching the permanent
config, pass an override struct instead of editing `cfg_TwoPoint.m`:

```matlab
CFG = cfg_TwoPoint();
CFG.samples          = {'Жовч'};
CFG.paths.examples   = {'zrazok_2'};
CFG.algorithms        = {'orthogonal'};
CFG.ortho.steps        = [1];
CFG.ortho.directions   = {'OY'};     % only OY, OX left untouched
run_TwoPoint_Pipeline(CFG);
```

## Layout

```
run_TwoPoint_Pipeline.m   main entry (paths + sample/example/algorithm loops + save)
config/cfg_TwoPoint.m     ALL parameters -> struct CFG
core/
  tp_load_images.m        load real BMPs (sample + optional example subfolder)
                           or simulate (source='synthetic')
  tp_gen_synthetic.m      (legacy) simple synthetic speckle — not used
  tp_slice.m              slice the nested image struct
  tp_fik_pair.m           formulas (1),(6)-(13),(sect.4) -> 16 complex f_ik
  tp_algo_orthogonal.m    OX / OY maps, one call computes ALL CFG.ortho.steps;
                           directions toggle via CFG.ortho.directions
  tp_algo_generalized.m   ONE pseudo-ACF diagram per call, for a single step
                           (orchestrator loops CFG.gen.steps, saving/plotting
                           each step before moving to the next)
  tp_base_result.m        empty canonical result struct
  tp_validate.m           quality control (skip degenerate elements)
  tp_visualize.m          dispatcher: per dir -> overview + per-element figures
  tp_check_config.m       fail-fast CFG validation (core/tp_assert.m style)
  tp_acf_psd.m            shared 2D ACF/PSD (fast | direct)
io/tp_save_figure.m       folder routing + exportgraphics
viz/  (layout per hand-drawn wireframes; style per old/calc_2025_vis_DvotMM)
  viz_style.m             shared light-theme styling / fonts
  viz_overview.m          Part 01: 4x4 grids of all 16 f_ik (modules, arguments)
  viz_maps_hist.m         (1) 2x2: |f| map | Arg map ; |f| hist | Arg hist
  viz_sections.m          (2) 2x2: |f| contour | Arg contour ; |f| 3D | Arg 3D
  viz_contour3d.m         (2b) 1x2: |f| contour3 | Arg contour3 (contours in 3D)
  viz_wavelet.m           (3) 2x2: W(a,b) |f| + A(b) a=10/50 ; W(a,b) Arg + A(b)
  viz_acf_psd.m           (4A) 2x2: 2D ACF | 2D PSD, for module & argument
  viz_acf_cuts.m          (4B) 2x2: 1D ACF cuts (OX,OY) | their PSD (log-log)
  viz_skeleton.m          (5) 2x2: WTMM skeleton + F(h) of maxima, mod + arg
  viz_level_bands.m       (6) 4x4: mask + histogram per level, separate fig
                          per module/argument — where values concentrate
core/tp_smooth2.m         NaN-safe Gaussian smoothing, display-only (contour lines)
simulation/
  tp_sim_speckle_BT.m     physical sim: birefringent tissue (theta,delta) + speckle
                          -> all 24 images via one Jones operator, common scaling
  tp_sim_preview.m        preview theta/delta/speckle + example intensities
  tp_sim_stage01..05.m    stage helpers for run_TwoPoint_Simulation_analysis
test/
  tp_test_util.m          shared helpers (panelMap, stdMapPanel, saveFig, ranges)
  tp_test_stage01..05.m   stage helpers for run_TwoPoint_Pipeline_test
  tp_test_complexity_check.m  real-vs-complex report for one configuration
gif/
  tp_gif_writeframe.m     append one figure frame to a growing GIF file
  tp_gif_orthogonal.m     annotated demo animation of the orthogonal algorithm
  tp_gif_generalized.m    annotated demo animation of the generalized algorithm
```

Representations (4) and (5):
- (4) ACF & PSD — two methods via `CFG.acf.method`: `fast` (Wiener-Khinchin, FFT,
  zero-padded to match linear `xcorr2`) or `direct` (literal `xcorr2` + spectrum
  through the ACF). Both give the SAME ACF; `fast` is just quicker. Computed
  ONCE per element in `tp_visualize.m` (`meta.acfData`) and shared between (4A)
  `viz_acf_psd` and (4B) `viz_acf_cuts` — not recomputed per representation.
- (5) wavelet skeleton (WTMM: local maxima lines of |W(a,b)|) + histogram F(h)
  of the maxima amplitudes, for module and argument. The CWT itself (`viz_wavelet`,
  `viz_skeleton`) is computed once per element (not once per colormap).
- (2) contour lines are drawn on a lightly Gaussian-smoothed copy of the map
  (`CFG.viz.contourSmoothPx`, NaN-safe, display-only — `core/tp_smooth2.m`).
  Real (noisy, per-pixel) data otherwise breaks `contour()` into disconnected
  patches, since a line is only drawn exactly where a level is crossed. The
  3D surface panel and all other representations still use the raw data.
- (6) level-band concentration (`viz_level_bands.m`) — complements (2): for
  `CFG.viz.bandLevels` levels evenly spaced between min and max, shows WHERE
  pixels within `level ± CFG.viz.bandWidthPct/2 * (max-min)` are located (mask)
  and their value histogram (how tightly they actually cluster) — separate
  figures for module and argument.

Wavelet-based representations (3) and (5) extract a single 1D profile from the
2D map (`CFG.wavelet.profile`: `center_row` | `center_col` | `mean_row`) before
running the CWT — they analyze that profile, not the full 2D map.

## Output tree

```
Real data (CFG.source='real'):
<saveRoot>/<sample>/<example>/<algorithm>/result.mat
<saveRoot>/<sample>/<example>/<algorithm>/<DIR>/<step>/00_overview_modules_<cmap>.png
<saveRoot>/<sample>/<example>/<algorithm>/<DIR>/<step>/00_overview_arguments_<cmap>.png
<saveRoot>/<sample>/<example>/<algorithm>/<DIR>/<step>/<f_ik>/<f_ik>_maps_hist_<cmap>.png
                                                              <f_ik>_surf_contour_<cmap>.png
                                                              <f_ik>_contour3d_<cmap>.png
                                                              <f_ik>_wavelet_<cmap>.png
                                                              <f_ik>_acf_psd_2d_<method>_<cmap>.png
                                                              <f_ik>_acf_cuts_<method>.png
                                                              <f_ik>_skeleton_<cmap>.png
   algorithm = orthogonal | generalized
   DIR, step (orthogonal) = OX | OY,  then  step_1 | step_2 | step_4 | step_8 | step_16 | step_32
   DIR, step (generalized) = step_1 | step_2 | ... (no separate DIR level — one folder per step)
   cmap = jet | gray            (CFG.viz.colormaps)

Synthetic demo (CFG.source='synthetic'): same tree, minus the <example> level
   <saveRoot>/<sample>/<algorithm>/<DIR>/<step>/...
```

## Doc → code mapping

| Spec | Implemented in |
|------|----------------|
| Матрицы Мюллера (1),(6)-(13),(sect.4) | `core/tp_fik_pair.m` |
| Ортогонально-направленный (OX и OY, раздельно) | `core/tp_algo_orthogonal.m` |
| Обобщённый (усреднение по (Δx,Δy), круговое для arg) | `core/tp_algo_generalized.m` |
| Representations ①–⑤ | `viz/viz_maps_hist` / `viz_sections` + `viz_contour3d` / `viz_wavelet` / `viz_acf_psd` + `viz_acf_cuts` / `viz_skeleton` |

## Extension points (append, don't rewrite)

- **New sample / element subset / toggle** → edit `CFG`.
- **New real sample** → add its folder name to `CFG.samples`; it must contain
  the sub-folders listed in `CFG.paths.examples`, each with the 24 `*.bmp`
  files (`0-0.bmp` … `prav-prav.bmp`).
- **New algorithm** → add `core/tp_algo_<name>.m` returning a `tp_base_result`
  struct; add a `case`/branch in `run_TwoPoint_Pipeline` and the name to `CFG.algorithms`.
- **New representation** → add `viz/viz_<name>.m(D, meta, ctx, CFG)`; call it from
  `tp_visualize` behind a `CFG.viz.<name>` flag (via the `runViz` wrapper).
- **Orthogonal separations** → edit `CFG.ortho.steps` (e.g. `[1 2 4 8 16]`);
  each value yields a separate `OX/step_<N>` and `OY/step_<N>` map. Narrow
  `CFG.ortho.directions` to `{'OX'}` or `{'OY'}` to (re)compute only one.
- **Generalized steps** → edit `CFG.gen.steps` (e.g. `[32 16 8 4 2 1]`); each
  value is computed, saved and plotted before the next one starts — safe to
  interrupt a long run, already-finished steps stay on disk.

## Demo GIFs (mechanics explainer)

`run_TwoPoint_GIF_Demo.m` builds two annotated GIF animations on a small
synthetic sample, showing HOW each algorithm overlaps and computes — with the
formula and a live numeric example burned into every frame:

```matlab
cd C:\Users\Yurii\Documents\MATLAB\july2026
run_TwoPoint_GIF_Demo
```

- `gif/orthogonal_algorithm.gif` — reveals the OX and OY maps pixel-row/column
  by pixel-row/column as the first point r1 scans the image; no averaging,
  each pixel gets its own value.
- `gif/generalized_algorithm.gif` — slides a shifted copy of the field over
  itself for each Δ (same mechanic as an autocorrelation), highlights the
  overlap region, and reveals the pseudo-ACF diagram cell by cell, printing
  the averaged value and pair count for the current Δ.

Uses the same `tp_fik_pair` / pairing logic as the real algorithms, just on an
80×80 demo crop for speed — a faithful, not schematic, illustration.

## Diagnostics (step-by-step analysis)

`run_TwoPoint_Pipeline_test.m` (project root; stage helpers in `test/tp_test_*`)
traces the whole f_ik computation chain for ONE configuration (one sample, one
direction, one step) and saves every step as figures (with value ranges), to
`<saveRoot>/<sample>/TEST_ANALYSIS/<DIR>_step_<step>/`:

```
Check     complexity report: which quantities are REAL vs COMPLEX (max|Im|),
          written to complexity_report.txt (intermediates must be real; f_ik
          are complex by construction; sqrt is guarded against negative I)
Stage 01  input images I0..Iprav (per illumination)
Stage 02  amplitudes |Ex|,|Ey| and phase delta at points 1 and 2
Stage 03  intermediate real components a_i, b_i (i=1..4) per illumination
Stage 04  assembly of each f_ik: Re | Im | |f| | arg (+ FLAT flag)
Stage 05  intervals of variation per element (min..max, mean +/- std) for
          Re/Im/|f|/arg + numeric table stage05_summary.csv
```

Run:

```matlab
cd C:\Users\Yurii\Documents\MATLAB\july2026
run_TwoPoint_Pipeline_test
```

Pick the case via `CFG.test.sample` / `.direction` ('OX'|'OY') / `.step`
(defaults to the first sample and the first `CFG.ortho.steps` value).

## Simulation diagnostics (how the synthetic sample is built)

`run_TwoPoint_Simulation_analysis.m` (stage helpers in `simulation/tp_sim_stage*`)
traces the construction of the synthetic birefringent-tissue field, saved to
`<saveRoot>/<sample>/SIM_ANALYSIS/`:

```
Sim 01  architectonics: optical axis theta + retardance delta (birefringence)
Sim 02  Jones operator J(theta,delta) magnitudes |J11|..|J22|
Sim 03  coherent speckle carrier: |s|, phase, intensity
Sim 04  output fields Ex, Ey (amp/phase) per illumination
Sim 05  formed intensities I0..Iprav per illumination
```

`tp_sim_preview.m` gives a quicker single-figure look at theta/delta/speckle +
example intensities, same output folder. Tune the model via `CFG.sim.*`
(axis/retardance/speckle correlation lengths, retardance range).

## Robustness & validation

- **Fail-fast config check:** every launcher calls `tp_check_config(CFG)` first —
  bad config (missing `CFG.paths.examples` for real data, unreadable `readRoot`,
  invalid `CFG.ortho.directions`, etc.) is reported early with a clear message.
- **Preconditions** in key functions (`tp_load_images` crop bounds, `tp_fik_pair`
  pair sizes, `tp_sim_speckle_BT` sim params) throw clear errors — they are NOT
  swallowed; the outer wrapper logs them with context.
- **Boundary error handling:** the orchestrator (per sample/example/algorithm),
  the visualization dispatcher (`runViz` per representation), and the test/
  simulation stage launchers each wrap calls in try/catch, so one failing
  figure/stage/sample logs `[fail] ...` / `[viz fail] ...` / `[skip sample] ...`
  and the rest of the run still completes.
- **TeX-safe titles:** figure titles use a display-only copy of the sample name
  (`\` and `/` replaced with ` / `) so a combined `sample\example` identifier
  never breaks the TeX title interpreter; the raw name (with `\`) is still used
  for the actual folder path.

## Notes

- Border pixels with no valid partner stay `NaN`; QC (`tp_validate`) drops maps
  that are all-NaN, mostly-NaN, or near-constant — they are not saved.

- **Orthogonal** (`core/tp_algo_orthogonal.m`) — distances are the explicit list
  `CFG.ortho.steps` (e.g. `[32 16 8 4 2 1]`); OX and OY are always independent,
  each pixel gets its own value (no averaging). Two extra knobs:
  - `CFG.ortho.posStep` — THINNING of first points (1 = every pixel; >1 = coarser
    spatial map, faster, more NaN near the sparse grid).
  - `CFG.ortho.directions` — subset of `{'OX','OY'}` (default both); narrow it
    to recompute just one direction without touching the other.

- **Generalized** (`core/tp_algo_generalized.m`) — for each step in
  `CFG.gen.steps`, builds one pseudo-ACF diagram indexed by separation (Δx,Δy)
  in `[-maxDist, maxDist]` at that step's grid spacing, averaged over all first
  points (module: arithmetic mean; argument: circular mean). Two knobs:
  - `CFG.gen.posStep` — THINNING of first points averaged into each Δ-cell
    (1 = every pixel). If a step equals 1 (the heaviest, densest grid), the
    effective thinning auto-bumps to `max(posStep, 2)` for speed — steps > 1
    use `posStep` exactly as configured.
  - `CFG.gen.maxDist` (`[]` => `crop.size - 1`, i.e. full range).
  - `CFG.gen.parallel = true` runs each step with `parfor` across physical
    CPU cores (columns of the Δx grid).
  - The orchestrator computes/saves/plots ONE step at a time — safe to
    interrupt a long batch (e.g. many steps queued overnight).

- **Figure rendering is parallelized too** (`core/tp_visualize.m`, `CFG.viz.parallel`,
  default `true`): the numeric part of `tp_algo_orthogonal` is already fast
  (vectorized matrix ops), so the real bottleneck for orthogonal was the
  per-element figure loop (16 elements × representations × 2 colormaps)
  running on a single core. `tp_visualize` now runs that loop as a `parfor`
  across CPU cores — only the current element's data is sent to each worker
  (sliced via `Dlist{v}`, not the whole result struct). Set
  `CFG.viz.parallel = false` to force the old sequential behavior.
  - **Gotcha (fixed):** any dot-indexed reference to the result struct `R`
    (e.g. `R.algorithm`) INSIDE the `parfor` body forces MATLAB to broadcast
    the entire `R` to every worker — not just the field used. For orthogonal,
    `R` holds every step × both directions in one struct (can be >1 GB at
    `crop.size=500`), which crashed with `Out of Memory during deserialization`.
    Fixed by copying small scalars (e.g. `algoName = R.algorithm;`) OUTSIDE
    the loop and referencing only those inside — keep this pattern when
    adding new fields to the `parfor` body.

- Requires Wavelet Toolbox for representations (3) and (5), and Image
  Processing Toolbox (`rgb2gray`, used for real BMPs; `rgb2ind`, used by the
  GIF demo).
