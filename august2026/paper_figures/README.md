# paper_figures — рисунки у статтю (двоточкова матриця Мюллера)

Будує **готові до статті** рисунки з уже порахованих `result.mat`
(`cfg_TwoPoint.CFG.paths.saveRoot`). Нічого не рахує у `f_ik` — читає сирі
`mod`/`arg`-карти; АКФ/PSD рахуються на льоту (`august2026/core/tp_acf_psd.m`).

## Рисунки

| | зверху (ряди карт) | знизу (під картами) | таблиця | `kind` |
|---|---|---|---|---|
| **Fig1** | сирі 2D-карти `\|f\|` / `arg` | гістограми значень | `stats.moments` — Z₁…Z₄ | `raw` |
| **Fig2** | 2D-**АКФ** + контур напівширини (0.5) | **3D-поверхня** тієї ж АКФ | `stats.acf` — Z₂, Z₄, L | `acf` |
| **Fig3** | 2D-**спектри потужності** `log₁₀(PSD)` | гістограми значень PSD | `stats.psd` — Z₁…Z₄ | `psd` |
| **Fig4** | вейвлет-**скелетони** (WTMM-максимуми в площині b×a) | гістограми F(h) амплітуд максимумів | `stats.skeleton` — Z₁…Z₄ | `skel` |
| **Fig5** | **скалограми** `\|W(a,b)\|` (b×a, лог-масштаб) | гістограми `\|W\|` | `stats.wavelet` — Z₁…Z₄ | `wav` |

Fig4/Fig5 потребують **Wavelet Toolbox**; беруть 1D-профіль карти
(`FIG.wav.profile`) і рахують CWT.

Кожен — сітка **4×4** (2 фазові вікна × [ряд карт + ряд низу]), 16 панелей
(a)…(p). Охват однаковий для всіх ("≡ Рис.1"): по 2 пари елементів
(`f33-f44`, `f23-f24`), 3 тканини, приклади 1/3, алгоритми
generalized/OX/OY, `color`+`gray`, формати `svg`/`pdf`/`png`.

Осі 2D-карт: Fig1 — просторові px (невід'ємні, 0…N); Fig2/Fig3 — лаг АКФ /
частота спектра, **зі знаком, центр у 0**.

## Структура пакета

```
paper_figures/
  cfg_figures.m, fig_export.m, make_stats_table.m, run_all_figures.m   ← спільне
  common/
    tp_paper_read.m      читає result.mat -> сирі карти
    paper_prep.m         сира карта -> те, що показується (raw|acf|psd) + переріз/моменти
    render_grid_4x4.m    відмальовує сітку 4x4 (спільна для Fig1/2/3, параметр kind)
    make_grid_pair.m     двигун: зразок×приклад×варіант×колір -> файли
    stats_moments.m      Z1..Z4 розподілу
  fig01/  make_fig1_f33_f44.m   make_fig1_f23_f24.m    (kind='raw')
  fig02/  make_fig2_f33_f44.m   make_fig2_f23_f24.m    (kind='acf')
  fig03/  make_fig3_f33_f44.m   make_fig3_f23_f24.m    (kind='psd')
```

## Запуск

```matlab
addpath('august2026/paper_figures')
run_all_figures            % усі 3 рисунки (обидві пари) + 3 таблиці
```

Окремо:

```matlab
make_fig2_f33_f44          % лише Fig2, пара f33/f24
make_stats_table           % лише таблиці моментів (.txt + .docx)
```

Своя конфігурація: `run_all_figures(myFIG)`, `myFIG = cfg_figures()` з правками.

## Тека виводу (`FIG.out.root`, типово `C:\August 2026-Results\Розрахунки - Скомпановані рисунки`)

Кожен формат — у своїй підтеці, усередині ще підтека алгоритму (в одну
теку картинок збирається багато — так легше шукати):

```
Fig1/ color/ svg/ generalized/  Fig1.f33-f44.generalized.heart.zrazok1.color.svg
                                 (+ Fig1.f23-f24. ... поряд)
             svg/ OX/|OY/  ...   png/|pdf/ <те саме>   gray/ <те саме>
      stats.moments.<variant>.txt/.docx   (моменти цього рисунка — окремий файл на алгоритм)
Fig2/ ... (stats.acf.<variant>)   Fig3/ ... (stats.psd.<variant>)   ...   Fig7/ ... (stats.mueller.<variant>)
```

Теги зразків: `heart` / `muscle` / `brain`; приклад — `FIG.exampleTag`
(типово `zrazok`: `zrazok1`, `zrazok2`, ...). Роздільник в іменах — крапка.
Тег алгоритму — `generalized` / `OX` / `OY` (повна назва, не "XY").

## Ключові параметри (`cfg_figures.m`)

- `FIG.figNN_<пара>.*` — ОБСЯГ кожного рисунка/пари: `elems`, `elemTex`,
  `samples` (тканини), `examples`, `variants`. За замовчуванням однаковий —
  щоб звузити конкретний, правити його поля.
- `FIG.geom.*` — абстрактний макет (мм), `aspectW=180`; розмір фігури
  рахується з контенту (`figSize=[]`)
- `FIG.font` — Arial 10 pt (усе, без жирного)
- `FIG.color.maps.*` — jet (color) / gray
- `FIG.hist.norm` — `'count'` (без нормування)
- `FIG.acf.method` `'fast'` · `FIG.acf.cropFrac` 0.5 · `FIG.acf.cut` `'x'` (`'y'`/`'radial'`)
- `FIG.psd.log` `true` (log10) · `FIG.psd.cropFrac` 0.5 · `FIG.psd.clipPct` 1
- Межі colorbar-а: ОКРЕМО для стовпців `\|f\|` і `arg` (динамічні діапазони
  різняться на порядки)

## Прийняті рішення (можуть уточнюватись)

- АКФ/PSD рахуються від **сирих** `mod`/`arg` (як у `tp_analytics` проєкту —
  щоб числа збігалися); для `arg` з циклічним ±π скачком це наближення.
- Fig2, 1D-переріз — **горизонтальний** через пік (Δy=0); налаштувати `FIG.acf.cut`.
- Fig2 таблиця — Z₂, Z₄ **+ довжина кореляції** (FWHM того ж перерізу).
- Моменти рахуються з **того, що показано** на панелі (Fig3 — з `log₁₀ PSD`).

## Залежності

`august2026\config\cfg_TwoPoint.m` не потрібен. `august2026\core\` —
`tp_acf_psd.m`, `tp_acf_hwhm.m` (Fig2/Fig3). Statistics Toolbox не
обов'язковий. Report Generator — лише для `.docx`; `.txt`-таблиці будуються завжди.
