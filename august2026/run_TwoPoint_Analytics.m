function run_TwoPoint_Analytics(cfgOverride, force)
% RUN_TWOPOINT_ANALYTICS  Уся аналітика ОДНИМ запуском: збирає числові
%   зведення з готових result.mat -> будує читабельні графіки за
%   СКФ-триадою (статистика/кореляція/фрактал), ОКРЕМО ПО КОЖНОМУ
%   АЛГОРИТМУ (кожен у своїй теці, БЕЗ жодного спільного файлу зверху).
%   НІЧОГО не рахує в самих f_ik — result.mat лише читаються.
%
%   Два етапи всередині:
%     (1) "дорахунок" зведення — для КОЖНОГО елемента f_ik за КОЖНОЇ умови
%         (зразок x приклад x фазове вікно x алгоритм x напрям/крок) рахує
%         статистику + ACF HWHM + мультифрактал (D0/D1/D2, ширина/асиметрія
%         f(h)). Це важка частина (CWT на елемент). Результат кешується
%         ОКРЕМО ПО КОЖНОМУ АЛГОРИТМУ:
%             CFG.paths.analyticsRoot\<algorithm>\analytics_summary_table.mat (+ .csv)
%         (generalized\ , orthogonal\ , ...). Спільної таблиці зверху НЕМАЄ.
%     (2) з цих таблиць, ОКРЕМО по кожному algorithm:
%         22 фігури (4x4 сітка f_ik, вісь X = фазове вікно в градусах,
%         лінії по зразку, кольорова рамка на панелях із позначеною
%         закономірністю), зведена картинка-"зміст", highlights.csv і
%         сирі таблиці трендів/порівнянь — усе в тій самій теці <algorithm>\.
%
%   Кеш (етап 1) перераховується автоматично, лише якщо:
%       * жодної <algorithm>\analytics_summary_table.mat немає, АБО
%       * якийсь result.mat під CFG.paths.saveRoot новіший за найстарішу
%         з наявних <algorithm>\analytics_summary_table.mat, АБО
%       * заданий force.
%   Інакше беруться готові таблиці по теках (швидко — можна багато разів
%   переганяти лише графіки, не чекаючи на CWT).
%
%   Стара спільна таблиця CFG.paths.analyticsRoot\analytics_summary_table.mat
%   (якщо лишилась від попередніх версій) один раз автоматично
%   розноситься по теках алгоритмів і видаляється.
%
%   Вихід у CFG.paths.analyticsRoot:
%     <algorithm>\                                (generalized\ , orthogonal\ , ...)
%       analytics_summary_table.mat / .csv        (таблиця зведень ЦЬОГО алгоритму, етап 1)
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
%       run_TwoPoint_Analytics('force')        % примусово перерахувати таблиці зведень
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
legacyMat = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.mat');
legacyCsv = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.csv');

% ============================ ЕТАП 1: зведення (кеш по теках алгоритмів) ===
% Одноразова міграція старої спільної таблиці -> по теках алгоритмів.
if isempty(algoSummaryMats(CFG)) && isfile(legacyMat) && ~force
    S = load(legacyMat);
    if isfield(S,'T') && istable(S.T) && height(S.T) > 0 ...
            && ismember('algorithm', S.T.Properties.VariableNames)
        n = saveAlgoTables(CFG, S.T);
        fprintf('Стару спільну таблицю рознесено по %d теці(ах) алгоритмів.\n', n);
    end
    if isfile(legacyMat); delete(legacyMat); end
    if isfile(legacyCsv); delete(legacyCsv); end
end

algoMats = algoSummaryMats(CFG);
needRecompute = force || isempty(algoMats);
if ~needRecompute
    oldestCache = min([algoMats.datenum]);
    L = dir(fullfile(CFG.paths.saveRoot, '**', 'result.mat'));
    if ~isempty(L) && max([L.datenum]) > oldestCache
        needRecompute = true;
        fprintf('Знайдено result.mat новіші за кеш — таблиці зведень оновлюються.\n');
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
    n = saveAlgoTables(CFG, T);
    fprintf('Таблиці зведень збережено окремо по %d алгоритму(ах).\n', n);
    if isfile(legacyMat); delete(legacyMat); end
    if isfile(legacyCsv); delete(legacyCsv); end
else
    T = loadAlgoTables(CFG);
    fprintf('=== Етап 1: беру готові таблиці по теках (%d рядків, %d алгоритм(ів)). force -> перерахувати ===\n', ...
            height(T), numel(unique(string(T.algorithm))));
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

% ------------------------------------------------------------------------
function n = saveAlgoTables(CFG, T)
% Розносить довгу таблицю зведень T по теках алгоритмів:
%   CFG.paths.analyticsRoot\<algorithm>\analytics_summary_table.mat (+ .csv)
% Кожна тека містить ЛИШЕ рядки свого алгоритму. Повертає кількість тек.
algoCol = string(T.algorithm);
algos   = unique(algoCol, 'stable');
for ai = 1:numel(algos)
    algo  = algos(ai);
    Talgo = T(algoCol == algo, :);   % зберігається у .mat нижче (save за іменем)
    d = fullfile(CFG.paths.analyticsRoot, char(algo));
    if ~exist(d,'dir'); mkdir(d); end
    save(fullfile(d,'analytics_summary_table.mat'), 'Talgo', '-v7.3');
    writetable(T(algoCol == algo, :), fullfile(d,'analytics_summary_table.csv'));
end
n = numel(algos);
end

% ------------------------------------------------------------------------
function L = algoSummaryMats(CFG)
% dir-подібний список analytics_summary_table.mat у ПРЯМИХ підтеках
% analyticsRoot (по одній на алгоритм). Без wildcard у середині шляху —
% явний обхід підтек, щоб не залежати від версії MATLAB.
L = dir(CFG.paths.analyticsRoot);
L = L([L.isdir] & ~ismember({L.name}, {'.','..'}));
keep = false(1, numel(L));
for i = 1:numel(L)
    f = fullfile(L(i).folder, L(i).name, 'analytics_summary_table.mat');
    if isfile(f)
        d = dir(f);
        L(i).name = d.name; L(i).folder = d.folder;
        L(i).datenum = d.datenum; L(i).bytes = d.bytes; L(i).date = d.date;
        keep(i) = true;
    end
end
L = L(keep);
end

% ------------------------------------------------------------------------
function T = loadAlgoTables(CFG)
% Збирає назад одну довгу таблицю з усіх
%   CFG.paths.analyticsRoot\<algorithm>\analytics_summary_table.mat
% (для Етапу 2, який сам знову ріже її по algorithm).
L = algoSummaryMats(CFG);
parts = cell(1, numel(L));
for i = 1:numel(L)
    S = load(fullfile(L(i).folder, L(i).name));
    if isfield(S,'Talgo'),     parts{i} = S.Talgo;
    elseif isfield(S,'T'),     parts{i} = S.T;      % сумісність зі старим ім'ям
    else,                      parts{i} = table();
    end
end
parts = parts(~cellfun(@(t) isempty(t) || height(t)==0, parts));
if isempty(parts)
    T = table();
else
    T = vertcat(parts{:});
end
end
