function rowsCell = tp_an_collect_from_disk(CFG)
% TP_AN_COLLECT_FROM_DISK  Збирає рядки таблиці аналітики з УЖЕ ЗБЕРЕЖЕНИХ result.mat
%   Кроку B (змінна R2), не запускаючи Крок A/B заново: для кожного
%   зразок x приклад x фаза x алгоритм x напрям/крок із конфігу
%       <saveRoot>\<зразок>\<приклад>\<фаза>\<алгоритм>+LB_CB_rho\<напрям>\result.mat
%   рахує статистику (tp_stats_LB_CB_rho, без перезапису текстових файлів) і
%   повертає рядки. Аналог серпневого tp_analytics_collect_summaries.m.
%   Береться те, що є на диску; чого нема -- мовчки пропускається.

rowsCell = {};
[phaseNames, ks] = tp_select_phases(CFG);
for s = 1:numel(CFG.samples)
    for e = 1:numel(CFG.paths.examples)
        smp = CFG.samples{s};  ex = CFG.paths.examples{e};
        for p = 1:numel(phaseNames)
            for a = 1:numel(CFG.algorithms)
                algRoot = fullfile(CFG.paths.saveRoot, smp, ex, phaseNames{p}, [CFG.algorithms{a} '+LB_CB_rho']);
                if ~isfolder(algRoot), continue; end
                L = dir(algRoot);  L = L([L.isdir] & ~ismember({L.name}, {'.','..'}));
                for i = 1:numel(L)
                    f = fullfile(algRoot, L(i).name, 'result.mat');
                    if ~isfile(f), continue; end
                    S = load(f, 'R2');
                    if ~stepWanted(L(i).name, CFG.fik.steps), continue; end
                    rowsCell = [rowsCell, tp_stats_LB_CB_rho(S.R2, L(i).name, CFG, ks(p), false)]; %#ok<AGROW>
                end
            end
        end
    end
end
end

function tf = stepWanted(dName, steps)
tf = false;
for d = steps(:)'
    if endsWith(dName, sprintf('step_%d', d)), tf = true; return; end
end
end
