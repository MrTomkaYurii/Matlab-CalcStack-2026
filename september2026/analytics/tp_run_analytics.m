function tp_run_analytics(CFG, mode)
% TP_RUN_ANALYTICS  Аналітика статистики Кроку B -- ПОРТ серпневого
%   run_TwoPoint_Analytics.m (analysis_ММ) на 5 величин Кроку B. Відповідає на
%   питання "чи все добре і чи відрізняється статистика між зразками та по
%   фазових вікнах": НІЧОГО не рахує в самих LB/CB/rho, лише зводить статистику.
%
%   Етап 1 -- таблиця метрик (22, як у серпні) по кожній умові
%             зразок x приклад x фаза x алгоритм x напрям/крок x величина:
%             CFG.paths.analyticsRoot\<алгоритм>\analytics_summary_table.mat/.csv.
%             Рядки додаються НАЖИВО під час прогону (tp_run_LB_CB_rho) або
%             збираються з диска (mode = 'rebuild', tp_an_collect_from_disk).
%   Етап 2 -- окремо по кожному алгоритму: тренди по фазових вікнах і по кроках,
%             порівняння зразків (що розрізняє) і прикладів (відтворюваність),
%             22 рисунки (статистика / кореляція / фрактал), огляд-"зміст",
%             highlights.csv -- усе в тій самій теці <алгоритм>\.
%   Аналізуються лише зразки/приклади/вікна, що зараз обрані в CFG (samples,
%   paths.examples, fik.phases), і алгоритми з CFG.algorithms.
%
%   tp_run_analytics(CFG)            % Етап 2 з наявних таблиць
%   tp_run_analytics(CFG,'rebuild')  % спершу Етап 1 з диска (статистика перераховується)
%
%   Вихід (у CFG.paths.analyticsRoot\<алгоритм>\):
%     analytics_summary_table.mat/.csv, highlights.csv, trend_phase_windows.csv,
%     trend_scales.csv, compare_samples_discriminative.csv,
%     compare_examples_consistency.csv, figures\{statistics,correlation,fractal,summary}\*.png

if nargin < 2, mode = 'tables'; end

if strcmpi(mode, 'rebuild')
    fprintf('=== Аналітика, етап 1: збираю статистику з result.mat на диску ===\n');
    rows = tp_an_collect_from_disk(CFG);
    fprintf('Зібрано %d рядків (величина x умови).\n', numel(rows));
    tp_an_append_rows(CFG, rows);
end

metricVars = tp_an_metric_names();
catalog    = tp_an_metric_catalog();
groups     = {'statistics','correlation','fractal'};
order      = {'LB_0_90','LB_45_135','CB','rho','LB'};
[~, ks] = tp_select_phases(CFG);
if isfield(CFG,'style'), Sty = viz_style(CFG.style); else, Sty = viz_style(); end

fprintf('=== Аналітика, етап 2: тренди, порівняння, рисунки ===\n');
for a = 1:numel(CFG.algorithms)
    algo = CFG.algorithms{a};
    matFile = fullfile(CFG.paths.analyticsRoot, algo, 'analytics_summary_table.mat');
    if ~isfile(matFile)
        fprintf(2, '  [skip] %s: немає таблиці %s (спершу прогін Кроку B зі stepB.analytics=true або mode=''rebuild'')\n', algo, matFile);
        continue;
    end
    S = load(matFile);  T = S.Talgo;
    T = T(ismember(T.sample, string(CFG.samples)) & ismember(T.example, string(CFG.paths.examples)) ...
          & ismember(T.phase_index, ks), :);
    if isempty(T)
        fprintf(2, '  [skip] %s: у таблиці немає рядків для обраних зразків/прикладів/вікон\n', algo);
        continue;
    end
    outRoot = fullfile(CFG.paths.analyticsRoot, algo);
    figDir  = fullfile(outRoot, 'figures');
    nPh = numel(unique(T.phase_index));
    fprintf('\n--- %s : %d рядків, %d зразк(ів), %d фазових вікон ---\n', algo, height(T), numel(unique(T.sample)), nPh);
    if nPh < 3
        fprintf('  [увага] лише %d фазове вікно(а): тренд по вікнах потребує >= 3 (позначки "тренд" не буде)\n', nPh);
    end

    % сирі допоміжні таблиці
    trendPhase = tp_an_fit_trend(T, {'sample','example','algorithm','direction','step','element'}, 'phase_deg', metricVars);
    trendScale = tp_an_fit_trend(T, {'sample','example','algorithm','direction','phase_index','element'}, 'step', metricVars);
    [discrim, consist] = tp_an_compare_samples(T, metricVars);
    writetable(trendPhase, fullfile(outRoot,'trend_phase_windows.csv'));
    writetable(trendScale, fullfile(outRoot,'trend_scales.csv'));
    writetable(discrim,    fullfile(outRoot,'compare_samples_discriminative.csv'));
    writetable(consist,    fullfile(outRoot,'compare_examples_consistency.csv'));

    % 22 рисунки + огляд + highlights
    allS = struct();
    for g = 1:numel(groups)
        grp = groups{g};
        entries = catalog.(grp);
        for e = 1:numel(entries)
            metricName = entries{e}{1};
            Sm = tp_an_build_series(T, metricName, order, CFG.analytics.trendR2, CFG.analytics.discrimRatio);
            allS.(metricName) = Sm;
            viz_an_metric_grid(Sm, entries{e}{2}, entries{e}{3}, ...
                fullfile(figDir, grp, sprintf('trend_%s.png', metricName)), Sty);
        end
    end
    viz_an_overview(allS, catalog, fullfile(figDir, 'summary', 'highlights_overview.png'), Sty);
    tp_an_write_highlights(allS, catalog, fullfile(outRoot, 'highlights.csv'));
    fprintf('  готово: %s\n', fullfile(figDir, 'summary', 'highlights_overview.png'));
end
fprintf('\n=== аналітика: %s ===\n', CFG.paths.analyticsRoot);
end
