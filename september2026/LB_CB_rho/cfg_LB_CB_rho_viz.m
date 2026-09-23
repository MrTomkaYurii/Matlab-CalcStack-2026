function CFG = cfg_LB_CB_rho_viz()
% CFG_LB_CB_rho_VIZ  Єдине джерело налаштувань для наших (Крок B, 5
%   зелених величин) рисунків — той самий принцип, що й
%   august2026\paper_figures\cfg_figures.m (окремий конфіг-файл для
%   шрифту/кеглю/кольорів/DPI/форматів, відокремлений від конфігу Кроку A),
%   але БЕЗ мм-геометрії композитних Fig1-Fig7 — наші рисунки й далі прості
%   fig/subplot-и (viz_maps_hist.m, viz_block3_contours.m, ...), просто з
%   ОДНОГО місця стилізовані, а не розкидані по cfg_TwoPoint.m.
%
%   Форма струтктури CFG (.paths/.viz/.out/.acf/.qc/.style) свідомо
%   ТА САМА, що й у cfg_TwoPoint(), бо всі скопійовані viz_*.m/
%   tp_save_figure.m/tp_validate.m/tp_acf_psd.m читають саме такі поля —
%   це дає змогу передати CFG тим НЕЗМІНЕНИМ функціям без жодної правки
%   їхнього коду.

CFG = struct();

%% ─── ШЛЯХИ ──────────────────────────────────────────────────────────────
CFG.paths.matRoot  = 'C:\September 2026-Results\Зразки - нові (серпень 2026) mat';
CFG.paths.saveRoot = 'C:\September 2026-Results\Розрахунки - LB CB rho';

%% ─── ВИВІД (растр/DPI) ──────────────────────────────────────────────────
CFG.out.format     = 'png';
CFG.out.dpi        = 200;
CFG.out.closeAfter = true;    % закривати фігури одразу після збереження (пакетний режим)

%% ─── ШРИФТ / КЕГЛЬ (застосовує viz_style.m через CFG.style) ────────────
CFG.style.fontName  = 'Helvetica';
CFG.style.titleSize = 14;     % загальний заголовок (sgtitle)
CFG.style.subSize   = 12;     % заголовок панелі
CFG.style.labelSize = 11;     % підписи осей
CFG.style.smallSize = 10;     % компактні багатопанельні рисунки (level_bands і т.п.)
CFG.style.ink       = [0.12 0.12 0.12];   % колір тексту/осей

%% ─── КОЛЬОРИ / КАРТИ ────────────────────────────────────────────────────
CFG.viz.colormaps      = {'jet','gray'};   % цикл колірних мап
CFG.viz.histBins        = 80;    % кількість стовпців гістограми (вужчі біни)
CFG.viz.contourLevels   = 6;     % кількість рівнів контурів
CFG.viz.contourSmoothPx = 3;     % сигма (px) NaN-безпечного згладжування ЛИШЕ для ліній контурів
CFG.viz.bandLevels      = 8;     % (6) рівні концентрації -- viz_level_bands.m
CFG.viz.bandWidthPct    = 0.02;

%% ─── АКФ / PSD ──────────────────────────────────────────────────────────
CFG.acf.method = 'fast';   % 'fast' (Wiener-Khinchin) | 'direct' (xcorr2)

%% ─── ВЕЙВЛЕТ (viz_wavelet.m, viz_skeleton.m) ────────────────────────────
CFG.wavelet.name            = 'amor';   % аналітичний вейвлет Морле
CFG.wavelet.voicesPerOctave = 12;
CFG.wavelet.highlightScales = [2 25];   % 2 перерізи A(b): низький/високий масштаб
                                        % (найближчий реально доступний бін CWT
                                        % до кожного з цих цільових значень)
CFG.wavelet.scaleRange      = [1 50];   % показувати лише масштаби a в цьому інтервалі
CFG.wavelet.profile         = 'center_row'; % 'center_row'|'center_col'|'mean_row'
CFG.wavelet.onArg           = true;     % також перетворювати профіль аргументу

%% ─── МУЛЬТИФРАКТАЛ (viz_multifractal.m, viz_multifractal_dimensions.m) ──
CFG.multifractal.qRange = -5:0.5:5;   % діапазон порядків q для партиційної функції

%% ─── ЯКІСТЬ ДАНИХ (пропустити вироджену карту) ──────────────────────────
CFG.qc.enable     = true;
CFG.qc.maxNaNfrac = 0.95;
CFG.qc.minStd     = 1e-9;
end
