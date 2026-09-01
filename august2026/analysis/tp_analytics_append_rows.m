function tp_analytics_append_rows(CFG, rowsCell)
% TP_ANALYTICS_APPEND_ROWS  Дописує нові рядки в analytics_summary_table
%   (етап 1), не чекаючи окремого запуску run_TwoPoint_Analytics.m.
%   Якщо рядок з тим самим ключем (зразок/приклад/алгоритм/напрям/крок/
%   фазове вікно/елемент) вже є — ЗАМІНЮЄ його (не дублює): повторний
%   розрахунок тієї ж умови оновлює число, а не плодить копії.
%
%   Викликається наживо з run_TwoPoint_Pipeline.m одразу після розрахунку
%   й збереження result.mat — БЕЗ повторного читання з диска й повторного
%   рахунку ACF/мультифракталу (той самий прохід, дані вже в пам'яті).

if isempty(rowsCell), return; end
Tnew = vertcat(rowsCell{:});

if ~exist(CFG.paths.analyticsRoot,'dir'); mkdir(CFG.paths.analyticsRoot); end
outMat = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.mat');
outCsv = fullfile(CFG.paths.analyticsRoot, 'analytics_summary_table.csv');

keyVars = {'sample','example','algorithm','direction','step','phase_index','element'};
if isfile(outMat)
    S = load(outMat, 'T');
    Told = S.T;
    isDup = ismember(Told(:, keyVars), Tnew(:, keyVars));
    T = [Told(~isDup, :); Tnew];
else
    T = Tnew;
end

save(outMat, 'T', '-v7.3');
writetable(T, outCsv);
end
