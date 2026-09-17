function T = tp_analytics_collect_summaries(CFG)
% TP_ANALYTICS_COLLECT_SUMMARIES  Проходить по ВСІХ уже порахованих
%   result.mat (зразок x приклад x фазове вікно x алгоритм x напрям/крок —
%   та сама структура тек, що й tp_collect_sample_for_horsky.m), для
%   кожного елемента f_ik рахує числове зведення (tp_analytics_compute_
%   summary.m) і збирає ВСЕ в одну довгу таблицю (один рядок = один
%   елемент за конкретних умов). f_ik НЕ перераховується (читається
%   готовий result.mat), але ACF HWHM і мультифрактал рахуються заново
%   для кожного елемента — ці числа зараз ніде не збережені, лише
%   малюються у в'юерах.
%
%   T = tp_analytics_collect_summaries(CFG)

rowsCell = {};
examplesList = {''};
if isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
    examplesList = CFG.paths.examples;
end
phaseOn = isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable;
numK = 1; if phaseOn, numK = CFG.phase.numWindows; end
if phaseOn
    U = tp_phase_window_bounds(CFG);
end

for s = 1:numel(CFG.samples)
    sampleName = CFG.samples{s};
    for ei = 1:numel(examplesList)
        example = examplesList{ei};
        if isempty(example), sampleOut = sampleName; else, sampleOut = fullfile(sampleName, example); end

        for k = 1:numK
            if phaseOn
                phaseOut = fullfile(sampleOut, tp_phase_folder_name(CFG, k));
                phaseDeg = round(U(k)/pi*180);
            else
                phaseOut = sampleOut;
                phaseDeg = NaN;
            end

            % orthogonal: <OX|OY>\step_N\result.mat (змінна Rd)
            for dirLabel = {'OX','OY'}
                dirRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'orthogonal', dirLabel{1});
                if ~isfolder(dirRoot), continue; end
                stepDirs = dir(fullfile(dirRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(dirRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    step = sscanf(stepDirs(si).name, 'step_%d');
                    Sld = load(rFile, 'Rd');
                    rowsCell = appendElementRows(rowsCell, Sld.Rd, sampleName, example, ...
                        'orthogonal', dirLabel{1}, step, k, phaseDeg, CFG);
                end
            end

            % generalized: step_N\result.mat (змінна R, напрям завжди 'XY')
            genRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'generalized');
            if isfolder(genRoot)
                stepDirs = dir(fullfile(genRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(genRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    step = sscanf(stepDirs(si).name, 'step_%d');
                    Slg = load(rFile, 'R');
                    rowsCell = appendElementRows(rowsCell, Slg.R, sampleName, example, ...
                        'generalized', 'XY', step, k, phaseDeg, CFG);
                end
            end

            % polar: <PERP|OX|OY>\step_N\result.mat (змінна Rd, крок = радіус rho).
            % Той самий шлях, що й tp_collect_sample_for_horsky / tp_phase_trend.
            for dirLabel = {'PERP','OX','OY'}
                dirRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'polar', dirLabel{1});
                if ~isfolder(dirRoot), continue; end
                stepDirs = dir(fullfile(dirRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(dirRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    step = sscanf(stepDirs(si).name, 'step_%d');
                    Slp = load(rFile, 'Rd');
                    rowsCell = appendElementRows(rowsCell, Slp.Rd, sampleName, example, ...
                        'polar', dirLabel{1}, step, k, phaseDeg, CFG);
                end
            end

            % XY: ЗВЕДЕНА карта (OX+OY) — step_N\result.mat (змінна R), як generalized.
            xyRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'XY');
            if isfolder(xyRoot)
                stepDirs = dir(fullfile(xyRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(xyRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    step = sscanf(stepDirs(si).name, 'step_%d');
                    Slx = load(rFile, 'R');
                    rowsCell = appendElementRows(rowsCell, Slx.R, sampleName, example, ...
                        'XY', 'XY', step, k, phaseDeg, CFG);
                end
            end
        end
    end
end

if isempty(rowsCell)
    T = table();
else
    T = vertcat(rowsCell{:});
end
end

% ------------------------------------------------------------------------
function rowsCell = appendElementRows(rowsCell, R, sampleName, example, algo, dirLabel, step, k, phaseDeg, CFG)
newRows = tp_analytics_rows_for_result(R, sampleName, example, algo, dirLabel, step, k, phaseDeg, CFG);
rowsCell = [rowsCell, newRows]; %#ok<AGROW>
end
