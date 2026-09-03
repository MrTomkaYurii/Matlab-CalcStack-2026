function tp_analytics_append_rows(CFG, rowsCell)
% TP_ANALYTICS_APPEND_ROWS  Дописує нові рядки в таблиці зведень (етап 1),
%   не чекаючи окремого запуску run_TwoPoint_Analytics.m. Пише ОКРЕМО ПО
%   КОЖНОМУ АЛГОРИТМУ:
%       CFG.paths.analyticsRoot\<algorithm>\analytics_summary_table.mat (+ .csv)
%   (жодного спільного файлу зверху). Якщо рядок з тим самим ключем
%   (зразок/приклад/напрям/крок/фазове вікно/елемент) у теці свого
%   алгоритму вже є — ЗАМІНЮЄ його (не дублює): повторний розрахунок тієї
%   ж умови оновлює число, а не плодить копії.
%
%   Викликається наживо з run_TwoPoint_Pipeline.m одразу після розрахунку
%   й збереження result.mat — БЕЗ повторного читання з диска й повторного
%   рахунку ACF/мультифракталу (той самий прохід, дані вже в пам'яті).

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

    if isfile(outMat)
        S = load(outMat);
        if isfield(S,'Talgo'),     Told = S.Talgo;
        elseif isfield(S,'T'),     Told = S.T;      % сумісність зі старим ім'ям
        else,                      Told = table();
        end
        if height(Told) > 0
            isDup = ismember(Told(:, keyVars), sub(:, keyVars));
            Talgo = [Told(~isDup, :); sub];
        else
            Talgo = sub;
        end
    else
        Talgo = sub;
    end

    save(outMat, 'Talgo', '-v7.3');
    writetable(Talgo, outCsv);
end
end
