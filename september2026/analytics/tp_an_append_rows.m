function tp_an_append_rows(CFG, rowsCell)
% TP_AN_APPEND_ROWS  Дописує рядки в таблицю аналітики ОКРЕМО ПО КОЖНОМУ
%   АЛГОРИТМУ:
%       CFG.paths.analyticsRoot\<algorithm>\analytics_summary_table.mat (+ .csv)
%   ПОРТ серпневого analysis_ММ\tp_analytics_append_rows.m без змін логіки:
%   рядок з тим самим ключем (зразок/приклад/напрям/крок/фазове вікно/елемент)
%   ЗАМІНЮЄ старий (повторний розрахунок тієї ж умови оновлює число, а не
%   плодить копії).

if isempty(rowsCell), return; end
Tnew = vertcat(rowsCell{:});

if ~exist(CFG.paths.analyticsRoot,'dir'); mkdir(CFG.paths.analyticsRoot); end
keyVars = {'sample','example','algorithm','direction','step','phase_index','element'};

algoCol = string(Tnew.algorithm);
algos   = unique(algoCol, 'stable');
for ai = 1:numel(algos)
    algo = algos(ai);
    sub  = Tnew(algoCol == algo, :);

    d = fullfile(CFG.paths.analyticsRoot, char(algo));
    if ~exist(d,'dir'); mkdir(d); end
    outMat = fullfile(d, 'analytics_summary_table.mat');
    outCsv = fullfile(d, 'analytics_summary_table.csv');

    Talgo = sub;
    if isfile(outMat)
        S = load(outMat);
        if isfield(S,'Talgo') && height(S.Talgo) > 0
            Told = S.Talgo;
            isDup = ismember(Told(:, keyVars), sub(:, keyVars));
            Talgo = [Told(~isDup, :); sub];
        end
    end

    save(outMat, 'Talgo', '-v7.3');
    writetable(Talgo, outCsv);
end
end
