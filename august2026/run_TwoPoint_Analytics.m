function run_TwoPoint_Analytics(cfgOverride, force)
% RUN_TWOPOINT_ANALYTICS  Уся аналітика ОДНИМ запуском: збирає числові
%   зведення з готових result.mat -> будує читабельні графіки за
%   СКФ-триадою (статистика/кореляція/фрактал), ОКРЕМО ПО КОЖНОМУ
%   АЛГОРИТМУ (кожен у своїй теці). НІЧОГО не рахує в самих f_ik —
%   result.mat лише читаються.
%
%   Два етапи всередині:
%     (1) "дорахунок" зведення — для КОЖНОГО елемента f_ik за КОЖНОЇ умови
%         (зразок x приклад x фазове вікно x алгоритм x напрям/крок) рахує
%         статистику + ACF HWHM + мультифрактал (D0/D1/D2, ширина/асиметрія
%         f(h)). Це важка частина (CWT на елемент). Результат кешується в
%         CFG.paths.analyticsRoot\analytics_summary_table.mat (+ .csv):
%         одна СПІЛЬНА довга таблиця з колонкою `algorithm`.
%     (2) з цієї таблиці, ОКРЕМО по кожному algorithm у ній:
%         22 фігури (4x4 сітка f_ik, вісь X = фазове вікно в градусах,
%         лінії по зразку, кольорова рамка на панелях із позначеною
%         закономірністю), зведена картинка-"зміст", highlights.csv і
%         сирі таблиці трендів/порівнянь.
%
%   Кеш (етап 1) перераховується автоматично, лише якщо:
%       * analytics_summary_table.mat відсутній, АБО
%       * якийсь result.mat під CFG.paths.saveRoot новіший за кеш, АБО
%       * заданий force.
%   Інакше береться готова таблиця (швидко — можна багато разів
%   переганяти лише графіки, не чекаючи на CWT).
%
%   Вихід у CFG.paths.analyticsRoot:
%     analytics_summary_table.mat / .csv          (спільна таблиця, етап 1)
%     <algorithm>\                                (generalized\ , orthogonal\ , ...)
%       figures\statistics\*.png    (8)
%       figures\correlation\*.png   (4)
%       figures\fractal\*.png       (10)
%       figures\summary\highlights_overview.png
%       highlights.csv
%       trend_phase_windows.csv, trend_scales.csv,
%       compare_samples_discriminative.csv, compare_examples_consistency.csv
%
%   Використання:
%       run_TwoPoint_Analytics                 % авто: кеш оновлюється лише за потреби
%       run_TwoPoint_Analytics('force')        % примусово перерахувати таблицю зведень
%       run_TwoPoint_Analytics(myCFG)          % власна структура CFG
%       run_TwoPoint_Analytics(myCFG, true)    % власний CFG + примусовий перерахунок

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), fullfile(here,'core'), fullfile(here,'analysis'), fullfile(here,'viz'));

% ---- аргументи: (CFG?, force?) з дозволом run_TwoPoint_Analytics('force') ----
if nargin < 2, force = false; end
if nargin >= 1 && (ischar(cfgOverride) || isstring(cfgOverride))
    force = strcmpi(string(cfgOverride), 'force');
    cfgOverride = [];
end
if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end
force = isequal(force, true) || strcmpi(string(force), 'force');

if ~exist(CFG.paths.analyticsRoot,'dir'); mkdir(CFG.paths.analyticsRoot); end
outMat = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.mat');
outCsv = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.csv');

% ============================ ЕТАП 1: зведення (кеш) ======================
needRecompute = force || ~isfile(outMat);
if ~needRecompute
    cacheInfo = dir(outMat);
    L = dir(fullfile(CFG.paths.saveRoot, '**', 'result.mat'));
    if ~isempty(L) && max([L.datenum]) > cacheInfo.datenum
        needRecompute = true;
        fprintf('Знайдено result.mat новіші за кеш — таблиця зведень оновлюється.\n');
    end
end

if needRecompute
    fprintf('=== Етап 1: зведення (ACF HWHM + мультифрактал, по кожному елементу) ===\n');
    T = tp_analytics_collect_summaries(CFG);
    fprintf('Зібрано %d рядків (елемент x умови).\n', height(T));
    if height(T) == 0
        fprintf(2, 'Нічого не знайдено в %s — спочатку запусти run_TwoPoint_Pipeline.m.\n', CFG.paths.saveRoot);
        return;
    end
    save(outMat, 'T', '-v7.3');
    writetable(T, outCsv);
else
    S = load(outMat, 'T'); T = S.T;
    fprintf('=== Етап 1: беру готову таблицю зведень (%d рядків). force -> перерахувати ===\n', height(T));
end

% ============================ ЕТАП 2: графіки по алгоритмах ================
metricVars = tp_analytics_metric_names();
catalog    = tp_analytics_metric_catalog();
groups     = {'statistics','correlation','fractal'};

algoCol = string(T.algorithm);
algos   = unique(algoCol, 'stable');
fprintf('=== Етап 2: графіки окремо по %d алгоритму(ах): %s ===\n', ...
        numel(algos), strjoin(cellstr(algos), ', '));

for ai = 1:numel(algos)
    algo = algos(ai);
    Ta   = T(algoCol == algo, :);
    outRoot = fullfile(CFG.paths.analyticsRoot, char(algo));
    figDir  = fullfile(outRoot, 'figures');
    if ~exist(outRoot,'dir'); mkdir(outRoot); end
    fprintf('\n--- %s : %d рядків ---\n', algo, height(Ta));

    % сирі допоміжні таблиці (по дрібних умовах ЦЬОГО алгоритму)
    trendPhase = tp_analytics_fit_trend(Ta, ...
        {'sample','example','algorithm','direction','step','element'}, 'phase_deg', metricVars);
    trendScale = tp_analytics_fit_trend(Ta, ...
        {'sample','example','algorithm','direction','phase_index','element'}, 'step', metricVars);
    [discrim, consist] = tp_analytics_compare_samples(Ta, metricVars);
    writetable(trendPhase, fullfile(outRoot,'trend_phase_windows.csv'));
    writetable(trendScale, fullfile(outRoot,'trend_scales.csv'));
    writetable(discrim,    fullfile(outRoot,'compare_samples_discriminative.csv'));
    writetable(consist,    fullfile(outRoot,'compare_examples_consistency.csv'));

    % 22 фігури + зведений огляд + highlights
    allS = struct();
    for g = 1:numel(groups)
        grp = groups{g};
        entries = catalog.(grp);
        for e = 1:numel(entries)
            metricName = entries{e}{1};
            label      = entries{e}{2};
            unit       = entries{e}{3};
            Sm = tp_analytics_build_series(Ta, metricName);
            allS.(metricName) = Sm;
            outFile = fullfile(figDir, grp, sprintf('trend_%s.png', metricName));
            viz_analytics_metric_grid(Sm, label, unit, outFile);
        end
    end
    viz_analytics_overview(allS, catalog, fullfile(figDir, 'summary', 'highlights_overview.png'));
    tp_analytics_write_highlights(allS, catalog, fullfile(outRoot, 'highlights.csv'));

    fprintf('  готово: %s\n', fullfile(figDir, 'summary', 'highlights_overview.png'));
end

fprintf('\n=== done: %s ===\n', CFG.paths.analyticsRoot);
end
