function FIG = cfg_figures()
% CFG_FIGURES  Єдине джерело налаштувань пакета august2026\paper_figures.
%   Рисунки будуються НЕ з нуля: читаються вже пораховані result.mat під
%   FIG.data.saveRoot. У f_ik нічого не рахується — лише mod/arg-карти для
%   панелей + моменти Z1..Z4 для таблиць.
%
%   ЗМІСТ (секції — згортаються в редакторі, «%%»):
%     1  ВИВІД            куди й у яких форматах
%     2  ЩО БУДУВАТИ      FIG.build (вибір рисунків)
%     3  ДЖЕРЕЛО ДАНИХ    saveRoot, крок, нормування масштабу
%     4  СЛОВНИК ІМЕН     теги зразків/прикладів, варіанти, фазові вікна
%     5  ОХВАТ РИСУНКІВ   елементи / зразки / приклади / варіанти
%          5c  ПЕР-ФІГУРНЕ ЗВУЖЕННЯ ОХВАТУ   <- правити ТУТ
%          5d  ПЕР-ФІГУРНІ ПАРАМЕТРИ .params <- правити ТУТ
%     6  МАКЕТ            геометрія панелей (мм)
%     7  ШРИФТ / ЛІНІЇ    + літери панелей
%     8  КОЛЬОРИ          colormap, межі, NaN
%     9  ОСІ КАРТ         одиниці, напрям, сітка
%    10  ГІСТОГРАМИ
%    11  АНАЛІТИКА        АКФ / PSD / вейвлет / скелетон / мультифрактал
%    12  ТАБЛИЦІ МОМЕНТІВ

FIG = struct();

%% 1 ─── ВИВІД ─────────────────────────────────────────────────────────────
%   Структура теки виводу:
%     FIG.out.root\ FigN\ <color|gray>\ <svg|pdf|png>\ <generalized|OX|OY>\ <файл>
%                        FigN\ stats.<набір>.txt / .docx   (таблиці моментів)
FIG.out.root    = 'C:\August 2026-Results\Розрахунки - Скомпановані рисунки';
FIG.out.formats = {'svg','pdf','png'};   % 'tiff' повернути у список для фіналу журналу
FIG.out.tiffDPI = 600;   % растровий TIFF (фінал): 300 фото / 600 змішане / 1200 штрих
FIG.out.pngDPI  = 300;   % PNG — прев'ю / вставити у Word чи лист

%% 2 ─── ЩО БУДУВАТИ (FIG.build) ───────────────────────────────────────────
%   Перелік завдань для run_all_figures І make_stats_table. Прибери/закоментуй
%   рядок у списку -> завдання пропускається. Регістр і порядок не важливі.
%     'Fig1' .. 'Fig6'  — ОБИДВІ пари елементів рисунка (f33-f44 і f23-f24)
%     'Fig3:f23f24'      — лише одна пара цього рисунка (':f33f44' / ':f23f24')
%     'Fig7'             — повна матриця Мюллера (усі 16, один рисунок)
%     'stats'            — таблиці моментів (.txt + .docx) обраних рисунків
%   Поодинокі рисунки й далі запускаються напряму: make_fig3_f23_f24(cfg_figures())
FIG.build = {'Fig1','Fig2','Fig3','Fig4','Fig5','Fig6','Fig7','stats'};

%% 3 ─── ДЖЕРЕЛО ДАНИХ ────────────────────────────────────────────────────
FIG.data.saveRoot = 'C:\August 2026-Results\Розрахунки - Двот. елем. ММ';
FIG.data.step     = 1;   % крок d (тека step_<d>); поки порахований лише 1

%   normalize — прибрати ДОВІЛЬНИЙ масштаб реконструйованих полів із карт f_ik
%   ПЕРЕД рисунками. Ex,Ey мають |E| ~ 1e-3 (нормування відновлення — поза цим
%   кодом), f_ik білінійні -> |f_ik| ~ 1e-6.
%     true  (типово): ділити всі |f_ik| на медіану |f_11| зразка/варіанта
%                     (m_ik = f_ik/f_11); arg не міняється; result.mat не чіпається.
%     false : сирі значення ~1e-6 (тоді в підписах — "arbitrary units").
%   Реалізація: common\tp_paper_normalize.m
FIG.data.normalize = true;

%% 4 ─── СЛОВНИК ІМЕН ─────────────────────────────────────────────────────
% зразок (тканина) -> короткий тег для ІМЕНІ ФАЙЛУ (латиниця, без пробілів)
FIG.sampleTag = { ...
    'Серце',      'heart'; ...
    'Мяз живота', 'muscle'; ...
    'Мозг',       'brain' };

% приклад (підтека 1/2/3) -> префікс у ІМЕНІ ФАЙЛУ ('ex' плутає — тому 'zrazok':
% zrazok1, zrazok2, ...). Латиниця, без пробілів.
FIG.exampleTag = 'zrazok';

% варіанти алгоритм/напрям: tag -> як шукати result.mat (tag іде в ІМ'Я ФАЙЛУ
% і в підтеку — "generalized", а не скорочення "XY").
%   generalized: saveRoot\<S>\<E>\<phase>\generalized\step_<d>\result.mat  (var R)
%   orthogonal : saveRoot\<S>\<E>\<phase>\orthogonal\<OX|OY>\step_<d>\result.mat (var Rd)
%   polar : saveRoot\<S>\<E>\<phase>\polar\<PERP|OX|OY>\step_<d>\result.mat (var Rd)
%           PERP — ЄДИНА карта (Σ_θ f); polarOX/polarOY — осьові зрізи того ж скану.
%   xysum : saveRoot\<S>\<E>\<phase>\xysum\<XY|OX|OY>\step_<d>\result.mat (var Rd)
%           XY — ЄДИНА карта (OX+OY, без ділення); xyOX/xyOY — осьові доданки.
FIG.variants = { ...
    struct('tag','generalized', 'algo','generalized', 'dir',''  ), ...
    struct('tag','OX',          'algo','orthogonal',  'dir','OX'), ...
    struct('tag','OY',          'algo','orthogonal',  'dir','OY') };
%   Розкоментуй ПІСЛЯ розрахунку polar / xysum (CFG.algorithms у cfg_TwoPoint.m).
%   Читання вже підтримане (common\tp_paper_read.m, case 'polar' / 'xysum'). Доти рядки
%   нижче лишай закоментованими — інакше кожен рисунок друкує "[skip] ... немає result.mat".
% FIG.variants(end+1:end+6) = { ...
%     struct('tag','PERP',    'algo','polar', 'dir','PERP'), ...
%     struct('tag','polarOX', 'algo','polar', 'dir','OX'), ...
%     struct('tag','polarOY', 'algo','polar', 'dir','OY'), ...
%     struct('tag','XY',      'algo','xysum', 'dir','XY'), ...
%     struct('tag','xyOX',    'algo','xysum', 'dir','OX'), ...
%     struct('tag','xyOY',    'algo','xysum', 'dir','OY') };

% фазові вікна = БЛОКИ рисунка (верхній -> нижній). Кожен блок = ряд карт +
% ряд гістограм/поверхонь під ними.
%   glob  — маска теки під saveRoot\<S>\<E>\  (01=2pi ... 08=0.25pi)
%   label — горизонтальний підпис НАД блоком (tex)
FIG.phase(1) = struct('glob','phase_01_*', 'label','0 - 2\pi');
FIG.phase(2) = struct('glob','phase_06_*', 'label','0 - 0.75\pi');

%% 5 ─── ОХВАТ РИСУНКІВ ───────────────────────────────────────────────────
%   Що САМЕ будувати: елементи, тканини, приклади, варіанти. Оформлення
%   (секції 6-12) спільне для всіх; тут — лише ОБСЯГ.
%
%   Кожен Fig1..Fig6 — у ДВОХ парах елементів (секції FIG.figNN_<пара>).
%   Fig7 — уся матриця Мюллера (окрема секція FIG.fig07).

% --- 5a. Спільний охват за замовчуванням (діє на КОЖЕН рисунок) -----------
def.samples  = {'Серце','Мяз живота','Мозг'};   % які тканини
def.examples = {'1','2','3'};                    % які приклади (підтеки 1/2/3)
def.variants = FIG.variants;                     % generalized + OX + OY

% --- 5b. Секції рисунків (будуються з def; НЕ чіпати — правити 5c/5d) -----
S = @(el, tex) struct('elems',{el}, 'elemTex',{tex}, ...
        'samples',{def.samples}, 'examples',{def.examples}, ...
        'variants',{def.variants}, 'params',{struct()});

FIG.fig01_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig1 сирі карти |f|/arg
FIG.fig01_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});
FIG.fig02_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig2 2D-АКФ + 3D-поверхня
FIG.fig02_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});
FIG.fig03_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig3 2D-PSD (log10) + гістограми
FIG.fig03_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});
FIG.fig04_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig4 вейвлет-скелетони (WTMM)
FIG.fig04_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});
FIG.fig05_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig5 скалограми |W(a,b)|
FIG.fig05_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});
FIG.fig06_f33f44 = S({'f33','f44'}, {'f_{33}','f_{44}'});   % Fig6 D(q) + спектр f(h), Delta h
FIG.fig06_f23f24 = S({'f23','f24'}, {'f_{23}','f_{24}'});

% Fig7 — не "пара елементів": УСЯ матриця Мюллера на ОДНОМУ рисунку
%   (|f_ik| зліва, arg(f_ik) справа, обидва фазові вікна). 4x(4x4)=64 панелі.
%   Макет common\render_mueller_grid.m, скрипт fig07\make_fig7_mueller.m.
FIG.fig07 = struct('samples',{def.samples}, 'examples',{def.examples}, ...
                   'variants',{def.variants}, 'params',{struct()});

% --- 5c. ПЕР-ФІГУРНЕ ЗВУЖЕННЯ ОХВАТУ ── правити ТУТ ─────────────────────
%   Розкоментуй потрібний рядок і зміни. Поля: .samples .examples .variants
%   .elems/.elemTex (пара елементів). Приклади:
%
% FIG.fig01_f33f44.samples  = {'Серце'};                 % лише серце
% FIG.fig03_f23f24.examples = {'2'};                     % лише приклад 2
% FIG.fig06_f33f44.variants = FIG.variants(1);           % лише generalized
% FIG.fig05_f23f24.elems    = {'f11','f22'};             % інша пара елементів
% FIG.fig05_f23f24.elemTex  = {'f_{11}','f_{22}'};
% FIG.fig07.samples         = {'Серце','Мозг'};
% FIG.fig07.examples        = {'1'};

% --- 5d. ПЕР-ФІГУРНІ ПАРАМЕТРИ ОФОРМЛЕННЯ (.params) ── правити ТУТ ──────
%   Глибоке злиття поверх спільних значень секцій 6-12 — САМЕ для цього
%   рисунка. Шлях = точний шлях поля нижче без "FIG.". Приклади:
%
% FIG.fig02_f33f44.params.acf.cropFrac   = 0.6;          % ширший кроп 2D-АКФ
% FIG.fig03_f33f44.params.psd.clipPct    = 2;
% FIG.fig06_f33f44.params.mfr.qRange     = -8:0.2:8;
% FIG.fig05_f23f24.params.wav.scaleRange = [3 150];
% FIG.fig01_f33f44.params.geom.histH     = 26;
% FIG.fig07.params.color.modClipPct      = 2;

%% 6 ─── МАКЕТ (геометрія панелей, мм) ────────────────────────────────────
%   16 панелей = 4 стовпці x 4 ряди: ряд1 карти(вікно1) / ряд2 низ / ряд3
%   карти(вікно2) / ряд4 низ. Стовпці: |f_a| arg(f_a) |f_b| arg(f_b).
%   Літери (a)..(p) — ПІД кожною панеллю; підпис фаз. вікна — НАД блоком.
%
%   Розмір фігури НЕ фіксуємо (figSize=[]): рахується з контенту. Значення —
%   АБСТРАКТНІ пропорції (мм): позиція осі = мм / повний абстрактний розмір.
FIG.geom.figSize = [];       % [] -> з контенту; [W H] см -> зафіксувати під журнал
FIG.geom.aspectW     = 180;  % абстрактна повна ширина
FIG.geom.marginL     = 15;   % ліворуч: вісь y карти стовпця 1
FIG.geom.marginR     = 6;    % праворуч
FIG.geom.marginT     = 4;    % зверху (навмисно = blockGap)
FIG.geom.marginB     = 6;    % знизу
FIG.geom.colGap      = 13;   % ВЕЛИКИЙ: у проміжок має вміститись вісь y НАСТУПНОЇ карти
FIG.geom.phaseHdrH   = 9;    % смуга підпису фазового вікна + лінія
FIG.geom.cbarStripH  = 1.8;  % кольорова смужка горизонтального colorbar-а (над картою)
FIG.geom.cbarTickH   = 6;    % цифри під смужкою colorbar-а
FIG.geom.titleH      = 6;    % заголовок стовпця (|f_a|, arg(f_a))
FIG.geom.histH       = 23;   % висота ряду гістограм
FIG.geom.surf3dH     = 34;   % висота ряду 3D-поверхонь (Fig2, ряди 2,4)
%   Зона ПІД панеллю = axisLabelH + letterGap + <висота літери> + letterGap.
%   Відступ НАД літерою (від підпису осі) і ПІД нею (до наступної панелі) —
%   ОДНАКОВІ = letterGap.
FIG.geom.axisLabelH   = 7.5;  % цифри осі x + назва осі під панеллю (10pt Arial)
FIG.geom.surf3dLabelH = 11;   % те саме для 3D-поверхні (проєкційні підписи нижчі)
FIG.geom.letterGap    = 2.2;  % ОДНАКОВИЙ відступ понад і під літерою панелі
FIG.geom.blockGap     = 4;    % між блоком фаз. вікна 1 і блоком 2 (навмисно = marginT)

%% 7 ─── ШРИФТ / ЛІНІЇ / ЛІТЕРИ ───────────────────────────────────────────
FIG.font.name = 'Arial';
FIG.font.size = 10;          % ЄДИНИЙ кегль: осі, цифри, заголовки, літери
FIG.line.axis = 0.75;        % pt, товщина рамки осей
FIG.panel.letterStyle = '(a)';   % '(a)' | 'a)' | 'a' | '(A)'
FIG.panel.letterBold  = false;   % літери під панелями — звичайні

%% 8 ─── КОЛЬОРИ ─────────────────────────────────────────────────────────
%   Кожен рисунок будується у ДВОХ варіантах — 'color' і 'gray' — в окремі
%   підтеки. FIG.color.modes задає перелік.
FIG.color.modes = {'color', 'gray'};
FIG.color.maps.color = struct('mod','jet',  'arg','jet');    % jet (школа Ушенка)
FIG.color.maps.gray  = struct('mod','gray', 'arg','gray');   % ЧБ (друк / colour-safe)
%   У 'gray' аргумент — лінійний -pi(чорний)..+pi(білий); розрив на ±pi неминучий.
FIG.color.argClim    = [-pi pi];   % фіксовані межі colorbar-а аргументу
FIG.color.modClipPct = 0;          % 0 = сирі min/max; >0 -> [prctile(p) .. prctile(100-p)]
FIG.color.nan        = [1 1 1];    % колір NaN-пікселів (край без пари / поза вікном)

%% 9 ─── ОСІ КАРТ + СІТКА ────────────────────────────────────────────────
FIG.axis.unit     = 'px';       % одиниці осей карт
FIG.axis.yDir     = 'normal';   % 'normal' (y вгору) | 'reverse' (як зображення)
FIG.map.grid      = true;       % сітка поверх карт
FIG.map.gridColor = [1 1 1];
FIG.map.gridAlpha = 0.35;
FIG.map.nGrid     = 4;          % орієнтовно стільки поділок сітки
%   Осі 2D-карт Fig2/Fig3 — ЗІ ЗНАКОМ, центр у 0 (лаг АКФ / частота спектра);
%   правило "без відʼємних" — лише для просторових карт Fig1.

%% 10 ─── ГІСТОГРАМИ ─────────────────────────────────────────────────────
FIG.hist.nbins = 40;            % однакові для панелей одного типу -> однакова ширина
FIG.hist.norm  = 'count';       % 'count' | 'probability' | 'pdf'
FIG.hist.fill  = [0.55 0.55 0.55];
FIG.hist.edge  = [0 0 0];
FIG.hist.edgeW = 0.3;           % pt

%% 11 ─── АНАЛІТИКА ─────────────────────────────────────────────────────
%   Усе рахується "на льоту" з тих самих сирих карт (core\tp_acf_psd.m,
%   core\tp_multifractal.m), від СИРИХ mod/arg.

% -- АКФ (Fig2) -----------------------------------------------------------
FIG.acf.method   = 'fast';      % 'fast' (Wiener-Khinchin) | 'direct' (xcorr2)
FIG.acf.cropFrac = 0.5;         % показувати центральні ±(cropFrac*макс. лаг) 2D-АКФ
FIG.acf.hwLevel  = 0.5;         % рівень контуру напівширини на 2D-АКФ (ряди карт)
FIG.acf.hwColor  = [0 0 0];
FIG.acf.hwW      = 1.3;         % pt
FIG.acf.surf3dN    = 90;        % цільова сітка 3D-поверхні (даунсемпл важкої АКФ)
FIG.acf.surf3dView = [-40 40];  % кут огляду [az el]
FIG.acf.surf3dEdge = [];        % [] -> чиста кольорова поверхня; [r g b] -> тонка сітка
FIG.acf.cut      = 'x';         % напрям 1D-перерізу для ЧИСЛА довжини кореляції: 'x'|'y'|'radial'

% -- PSD (Fig3) -----------------------------------------------------------
FIG.psd.cropFrac = 0.5;         % центральні ±(cropFrac*0.5) нормованої частоти
FIG.psd.log      = true;        % показувати log10(PSD)
FIG.psd.clipPct  = 1;           % межі colorbar-а за перцентилями (0 = сирі min/max)

% -- вейвлет W(a,b) (Fig5) + скелетон (Fig4) ----------------------------
FIG.wav.profile    = 'center_row';  % 'center_row' | 'center_col' | 'mean_row'
FIG.wav.wavelet    = 'amor';        % аналітичний вейвлет Морле
FIG.wav.voices     = 12;            % голосів на октаву
FIG.wav.scaleRange = [1 120];       % масштаби a у цьому діапазоні (px)
FIG.wav.yscale     = 'log';         % вісь масштабу a: 'log' | 'linear'
FIG.wav.coiMask    = true;          % за конусом впливу |W| -> NaN
FIG.wav.clipPct    = 1;             % межі colorbar-а |W| за перцентилями
FIG.skel.markerSize = 1;            % площа маркера scatter (pt^2); малий -> лінії не зливаються

% -- мультифрактали (Fig6) --------------------------------------------
FIG.mfr.qRange = -5:0.2:5;      % діапазон/крок q (дрібний крок біля 0 -> суцільна арка f(h))
FIG.mfr.row1   = 'Dq';         % ряд 1: 'Dq' | 'tau' | 'hq'
FIG.mfr.line   = [0.20 0.35 0.75];   % колір кривих
FIG.mfr.lineW  = 1.3;          % pt
FIG.mfr.marker = 3;            % розмір маркерів на кривій (pt)

%% 12 ─── ТАБЛИЦІ МОМЕНТІВ ─────────────────────────────────────────────
%   make_stats_table -> FigN\stats.<набір>.txt (вирівняні колонки) + .docx
%   (у стилі журналу). Набори: moments/acf/psd/skeleton/wavelet/multifractal/
%   mueller. Обсяг = FIG.build (секція 2).
FIG.stats.excessKurt = false;  % false: звичайний ексцес (норма 3); true: надлишковий (норма 0)
FIG.stats.docx       = true;   % будувати .docx (потребує MATLAB Report Generator)

end
