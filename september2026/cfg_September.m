function CFG = cfg_September()
% CFG_SEPTEMBER  ЄДИНЕ джерело ВСІХ налаштувань проєкту september2026: зразки,
%   алгоритми, шляхи, що рахувати й що малювати, стиль рисунків. Так само, як
%   колись august2026\config\cfg_TwoPoint.m -- щоб змінити прогін, достатньо
%   відредагувати лише цей файл (скрипти нічого не хардкодять).
%
%   Споживачі: run_LB_CB_rho_demo.m -> LB_CB_rho\tp_run_LB_CB_rho.m ->
%   tp_LB_CB_rho_from_result / tp_save_LB_CB_rho_result / tp_visualize_LB_CB_rho
%   та visualization\*.m, figure_export\tp_save_figure.m, august2026_copy\tp_validate.m (вони читають CFG.viz,
%   CFG.out, CFG.qc, CFG.acf, CFG.wavelet, CFG.multifractal, CFG.style,
%   CFG.paths.saveRoot -- імена полів ТІ САМІ, що в cfg_TwoPoint()).
%
%   Розділи:
%     1. ШЛЯХИ            2. ЗРАЗКИ (+2б модельний)  3. АЛГОРИТМИ + ФАЗОВІ ВІКНА
%     4. КРОК B           5. ЯКІСТЬ ДАНИХ        6. ЩО МАЛЮВАТИ (перемикачі)
%     7. ПАРАМЕТРИ ПОДАНЬ 7б. АНАЛІТИКА          8. СТИЛЬ І ВИВІД   9. КРОК A (довідково)

CFG = struct();

%% ══ 1. ШЛЯХИ ═════════════════════════════════════════════════════════════
% matRoot   -- сирі комплексні поля Ex,Ey реальних зразків (ex_*.mat/ey_*.mat); їх читає
%              Крок A (august2026_copy\tp_load_mat.m) та verify\scan_september_data_health.m.
% fikRoot -- ТУТ НАШ Крок A (fik_calculation\tp_run_fik_calc.m) зберігає result.mat (f_ik) для ВСІХ
%              зразків, реальних і модельних; звідси Крок B бере вхід.
%              Структура: <зразок>\<приклад>\<фаза>\<алгоритм>\...\result.mat
% saveRoot  -- куди Крок B пише числа (result.mat), статистику і рисунки.
% simRoot   -- сирі поля МОДЕЛЬНИХ зразків (генеруються, розділ 2б).
% fikAugustRoot -- ГОТОВІ August-результати Кроку A; потрібні ЛИШЕ при CFG.fik.source='august'.
CFG.paths.matRoot      = 'C:\September 2026-Results\Зразки - нові (серпень 2026) mat';
CFG.paths.fikRoot = 'C:\September 2026-Results\Розрахунки - Двот. елем. ММ';
CFG.paths.saveRoot     = 'C:\September 2026-Results\Розрахунки - LB CB rho';
CFG.paths.simRoot      = 'C:\September 2026-Results\Зразки - модельні (симуляція) mat';
CFG.paths.fikAugustRoot    = 'C:\August 2026-Results\Розрахунки - Двот. елем. ММ';

%% ══ 2. ЗРАЗКИ ════════════════════════════════════════════════════════════
% Прогін = samples × examples (декартів добуток, як у cfg_TwoPoint).
% Що рахувати ЗАРАЗ:
CFG.samples        = {'Серце', 'Мяз живота', 'Мозг'};    % усі три типи біологічних тканин
CFG.paths.examples = {'1', '2', '3'};                    % усі три приклади кожного зразка
% Повний перелік (для verify\scan_september_data_health.m і як підказка):
CFG.allSamples  = {'Серце', 'Мяз живота', 'Мозг'};
CFG.allExamples = {'1', '2', '3'};

% Відомо биті приклади (ex_90/ey_0 -- дійсні/нульові замість комплексних;
% встановлено СКАНУВАННЯМ verify\scan_september_data_health.m). Раннер їх
% пропускає, якщо не ввімкнено runBroken. Чисті: Серце\2, Серце\3, Мяз живота\1-3.
CFG.dataHealth.broken    = {'Серце\1', 'Мозг\1', 'Мозг\2', 'Мозг\3'};
CFG.dataHealth.runBroken = true;                        % true = рахувати навіть при нульових каналах (Серце\1)

%% ══ 2б. МОДЕЛЬНИЙ ЗРАЗОК (симуляція з july2026) ═══════════════════════════
% Не реальний зразок, а фізична модель двопроменезаломної тканини з ВІДОМОЮ
% істиною: лінійний ретардер з орієнтацією осі theta(x,y) і затримкою
% delta(x,y) + когерентний спекл-носій; усі входи/аналізатори проходять
% через ОДИН джонсів оператор (simulation\tp_sim_speckle_BT.m). Дозволяє
% перевірити весь ланцюжок на даних, де відповідь відома.
% СТВОРЮЄТЬСЯ ОКРЕМО: run_sim_model.m (генерація сирих полів моделі) запускається раз, ДО
% основного прогону; run_LB_CB_rho_demo модель НЕ створює -- бере готові сирі поля й рахує з них
% Крок A і Крок B так само, як для реальних зразків. У основний прогін модель потрапляє
% звичайним способом -- ім'ям у CFG.samples (розділ 2).
% Приклад (CFG.paths.examples) = номер реалізації: seed = sim.seed + 100*(приклад-1),
% тож приклад '1' -- точно оригінальна модель (seed 7), '2','3' -- інші реалізації.
CFG.simSamples = {'Модель'};        % які імена з CFG.samples генеруються симуляцією
CFG.sim.axisCorrLen    = 40;        % довжина кореляції орієнтації осі (px) -- «архітектоніка»
CFG.sim.retCorrLen     = 30;        % довжина кореляції затримки (px)
CFG.sim.speckleCorrLen = 6;         % довжина кореляції спеклу (px)
CFG.sim.retMin         = 0;         % мін. затримка (рад)
CFG.sim.retMax         = pi;        % макс. затримка (рад) -- сила двопроменезаломлення
CFG.sim.seed           = 7;         % базове зерно ГВЧ (як у july2026)
CFG.sim.fieldScale     = 1e-3;      % max|E| після спільного нормування (масштаб реальних реконструйованих полів); 0 = без
CFG.sim.stageFigures   = true;      % рисунки етапів Sim 01-05 при генерації (в <saveRoot>\<зразок>\<приклад>\SIM_ANALYSIS)
CFG.sim.regenerate     = false;     % true = створити сирі поля моделі заново, навіть якщо вони є (діє лише в
                                     % run_sim_model.m; Крок A моделі перераховується через CFG.fik.recompute)

%% ══ 3. АЛГОРИТМИ (вхід Кроку A) ═══════════════════════════════════════════
% Із результатів яких алгоритмів Кроку A рахувати LB, CB, rho:
%   'XY'         -- зведена карта OX+OY:  <фаза>\XY\step_d\result.mat
%   'orthogonal' -- окремо OX і OY:       <фаза>\orthogonal\OX\step_d\result.mat
%                                         <фаза>\orthogonal\OY\step_d\result.mat
%                   (у result.mat цього алгоритму змінна зветься Rd, не R --
%                   раннер розуміє обидві назви; напрями OX_step_d / OY_step_d)
% 'generalized' і 'polar' у Кроці B НЕ використовуються.
CFG.algorithms = {'XY', 'orthogonal'};

% ФАЗОВІ ВІКНА, для яких рахуємо (числа Кроку B, статистика, аналітика).
% Вікно k -- це тека phase_0k_[0-U_kpi]; ширина U_k звужується від повного кола:
%     k :   1          2          3          4          5          6          7          8
%   тека: [0-2.00pi] [0-1.75pi] [0-1.50pi] [0-1.25pi] [0-1.00pi] [0-0.75pi] [0-0.50pi] [0-0.25pi]
%   град:    360        315        270        225        180        135         90         45
% Задається НОМЕРАМИ вікон: 'all' (усі 8), або вектор, напр. 1, [1 3 5], 1:4.
% (Аналітика трендів по вікнах потребує щонайменше 3 вікон.)
CFG.fik.phases = 'all';
% Кроки рознесення d (папки step_<d>); рахується лише те, що в списку.
CFG.fik.steps = 1;
% ЗВІДКИ береться Крок A (f_ik) для РЕАЛЬНИХ зразків:
%   'compute' -- рахується з нуля з сирих полів matRoot нашим fik_calculation\tp_run_fik_calc.m -> fikRoot
%                (Серце/2 і Мяз живота/2 збігаються з August-результатами точно, різниця 0);
%   'august'  -- беруться готові result.mat з CFG.paths.fikAugustRoot (нічого не рахується).
% Модельні зразки (з їх сирих полів, які створює run_sim_model.m) завжди рахуються ('compute').
CFG.fik.source    = 'compute';
CFG.fik.recompute = false;     % true = перерахувати Крок A, навіть якщо result.mat уже є на диску

%% ══ 4. КРОК B (що рахуємо) ═══════════════════════════════════════════════
% Вхід (беруться з result.mat Кроку A, НЕ перераховуються):
%   f23, f32, f24, f42, f34, f43   (див. tp_LB_CB_rho_from_result.m)
% Вихід: LB_0_90, LB_45_135, CB, rho, LB -- завжди всі п'ять (rho і LB
% залежать від LB_0_90 і LB_45_135).
CFG.stepB.saveMat   = true;    % писати result.mat (числові карти mod/arg/cplx)
CFG.stepB.visualize = true;    % будувати рисунки (перемикачі й параметри нижче)
CFG.stepB.stats     = true;    % текстова статистика (mean, std, skew, kurt карти, АКФ, спектра, вейвлета, перерізів, скелетону +
                               % мультифрактал, як в августі): <елемент>_stats.txt у теці КОЖНОГО елемента
CFG.stepB.analytics = true;    % аналітика (як в analysis_ММ серпня): таблиця метрик, тренди по фазових
                               % вікнах, порівняння зразків, рисунки -> CFG.paths.analyticsRoot (розділ 6б)

%% ══ 5. ЯКІСТЬ ДАНИХ (пропустити вироджену карту) ═════════════════════════
CFG.qc.enable     = true;
CFG.qc.maxNaNfrac = 0.95;      % пропустити, якщо частка NaN більша
CFG.qc.minStd     = 1e-9;      % пропустити майже сталі карти
CFG.qc.minValidPixels = 1000;  % статистика: мінімум скінченних пікселів (як в аналітиці серпня); нижче -- NaN

%% ══ 6. ЩО МАЛЮВАТИ (перемикачі; імена як у cfg_TwoPoint, тут усе true) ═══
CFG.viz.elements     = {'LB_0_90','LB_45_135','CB','rho','LB'};   % які з п'яти малювати
CFG.viz.mapsHist     = true;   % (1)  2x2 карти + гістограми (мод+арг)
CFG.viz.blockSummary = true;   % Блок 1: карти -> гістограми -> АКФ однією фігурою
CFG.viz.surfContour  = true;   % (2)  2x2 3D-поверхні + контурні карти
CFG.viz.contour3     = true;   % (2b) контурні лінії у 3D
CFG.viz.blockContours = true;  % Блок 3: 2D контур + 3D контур однією фігурою
CFG.viz.multifractal = true;   % Блок 4: спектр f(h) з WTMM + D(q), tau(q)
CFG.viz.wavelet      = true;   % (3)  вейвлет W(a,b) (мод+арг)
CFG.viz.acfPsd       = true;   % (4A) 2D АКФ + 2D PSD
CFG.viz.acfCuts      = true;   % (4B) 1D перерізи ACF + їх PSD
CFG.viz.skeleton     = true;   % (5)  вейвлет-скелетон + гістограма максимумів
CFG.viz.levelBands   = true;   % (6)  смуговий аналіз (8 рівнів + рівень-мода)
% Для яких фазових вікон (номери, як в CFG.fik.phases) будувати РИСУНКИ. Вікна, яких тут нема, --
% лише числа, статистика й аналітика. Рисунків на одне вікно ~100 на напрям, тож 'all' -- довго
% (щоб швидше: 1 | [1 5] | 1:4). У вузьких вікнах (3-8) величини rho і LB часто не проходять QC
% (замало пікселів) -- рисунки для них пропускаються з повідомленням [skip].
CFG.viz.phases       = 'all';  % 'all' | 1 | [1 5] | 1:4

%% ══ 7. ПАРАМЕТРИ ПОДАНЬ ═════════════════════════════════════════════════
CFG.viz.colormaps       = {'jet','gray'};   % цикл колірних мап
CFG.viz.histBins        = 80;   % кількість стовпців гістограми
CFG.viz.contourLevels   = 6;    % кількість рівнів контурів
CFG.viz.contourSmoothPx = 3;    % сигма (px) NaN-безпечного згладжування ЛИШЕ для ліній контурів
CFG.viz.bandLevels      = 8;    % рівні концентрації (+1 рівень-мода) -- viz_level_bands.m
CFG.viz.bandWidthPct    = 0.02; % ширина смуги = ця частка діапазону (max-min)

% АКФ / PSD: 'fast' (Wiener-Khinchin, тотожний xcorr2) | 'direct' (xcorr2)
CFG.acf.method = 'fast';

% Вейвлет (viz_wavelet.m, viz_skeleton.m)
CFG.wavelet.name            = 'amor';       % аналітичний вейвлет Морле
CFG.wavelet.voicesPerOctave = 12;
CFG.wavelet.highlightScales = [2 25];       % 2 перерізи A(b): низький / високий масштаб
CFG.wavelet.scaleRange      = [1 50];       % показувати лише масштаби a у цьому інтервалі
CFG.wavelet.profile         = 'center_row'; % 'center_row'|'center_col'|'mean_row'
CFG.wavelet.onArg           = true;         % також перетворювати профіль аргументу

% Мультифрактал
CFG.multifractal.qRange = -5:0.5:5;         % порядки q для партиційної функції

%% ══ 7б. АНАЛІТИКА (аналог analysis_ММ з серпня; CFG.stepB.analytics) ═══════
% Таблиця метрик (22 як в серпні: моменти, півширина АКФ, мультифрактал) по всіх
% умовах -> тренд по фазових вікнах, порівняння зразків/прикладів, позначки
% ("тренд" / "розрізняє" / "обидва"), рисунки, highlights.csv. Окремо по кожному алгоритму:
%   <analyticsRoot>\<алгоритм>\{analytics_summary_table.mat/.csv, highlights.csv,
%                               trend_*.csv, compare_*.csv, figures\...}
CFG.paths.analyticsRoot = 'C:\September 2026-Results\Аналітика - LB CB rho';
CFG.analytics.trendR2     = 0.7;   % позначка "тренд": медіанний R^2 лінійного тренду по вікнах >= цього
CFG.analytics.discrimRatio = 1.5;  % позначка "розрізняє": розкид середніх між зразками > цього × типовий розкид усередині зразка

%% ══ 8. СТИЛЬ І ВИВІД ═════════════════════════════════════════════════════
CFG.style.fontName  = 'Helvetica';
CFG.style.titleSize = 14;     % загальний заголовок
CFG.style.subSize   = 12;     % заголовок панелі
CFG.style.labelSize = 11;     % підписи осей
CFG.style.smallSize = 10;     % компактні багатопанельні рисунки (level_bands і т.п.)
CFG.style.ink       = [0.12 0.12 0.12];   % колір тексту/осей

CFG.out.format     = 'png';
CFG.out.dpi        = 200;
CFG.out.closeAfter = true;    % закривати фігури після збереження (пакетний режим)

%% ══ 9. КРОК A (довідково) ═══════════════════════════════════════════════
% УВАГА: цей розділ читає ЛИШЕ august2026_copy\ при повному перерахунку f_ik з сирих
% полів (august2026_copy\tp_load_mat.m; самих tp_algo_*.m у september2026 ще немає).
% Крок B (усе вище) його НЕ використовує. Значення = як у august2026, за
% якими ПОРАХОВАНІ result.mat у fikAugustRoot.
CFG.source        = 'mat';    % готові КОМПЛЕКСНІ Ex,Ey з .mat
CFG.mat.rcSource  = 'prav';   % яке освітлення ('prav'|'liv') править за "RC"
CFG.crop.size     = 400;      % квадратна вирізка N x N
CFG.crop.x0       = 1;
CFG.crop.y0       = 1;

CFG.phase.enable     = true;
CFG.phase.numWindows = 8;             % вікна [0,U_k]: 2.00pi, 1.75pi, ... 0.25pi
CFG.phase.upperMax   = 2*pi;
CFG.phase.upperMin   = 0.25*pi;

els = cell(1,16); c = 0;              % усі 16 елементів f_ik
for i = 1:4
    for k = 1:4
        c = c + 1; els{c} = sprintf('f%d%d', i, k);
    end
end
CFG.elements = els;

CFG.ortho.steps      = [1];           % кроки d для OX/OY
CFG.ortho.posStep    = 1;             % 1 => усі пікселі
CFG.ortho.directions = {'OX','OY'};
CFG.XY.normalize     = true;          % f_ik / медіана|XY_11| (скаляр; на LB, CB, rho не впливає)
end
