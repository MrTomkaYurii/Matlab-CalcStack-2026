function run_Remask_Only()
% Швидка утиліта для перенакладання фазових вікон (2..10)
% з базових даних вікна 1 (0-2.00pi), без повного перерахунку алгоритмів.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), genpath(fullfile(here,'core')), ...
        fullfile(here,'io'), fullfile(here,'viz'), fullfile(here,'analysis_ММ'));

CFG = cfg_TwoPoint();
tp_check_config(CFG);

% Примусово вимикаємо всі картинки, щоб лише переписати .mat файли
CFG.viz.overview     = false;
CFG.viz.mapsHist     = false;
CFG.viz.blockSummary = false;
CFG.viz.surfContour  = false;
CFG.viz.contour3     = false;
CFG.viz.blockContours= false;
CFG.viz.wavelet      = false;
CFG.viz.acfPsd       = false;
CFG.viz.acfCuts      = false;
CFG.viz.skeleton     = false;
CFG.viz.levelBands   = false;
CFG.viz.statsTable   = false;

U = tp_phase_window_bounds(CFG);
baseWindowIdx = 1; % Найширше вікно, що містить усі дані
basePhaseFolder = tp_phase_folder_name(CFG, baseWindowIdx);

examplesList = {''};
if isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
    examplesList = CFG.paths.examples;
end

fprintf('=== Швидкий перерахунок масок (без зміни базових f_ik) ===\n');

for s = 1:numel(CFG.samples)
    sampleName = CFG.samples{s};
    
    for ei = 1:numel(examplesList)
        example = examplesList{ei};
        if isempty(example)
            sampleOut = sampleName;
            sampleLabel = sampleName;
        else
            sampleOut = fullfile(sampleName, example);
            sampleLabel = sprintf('%s / %s', sampleName, example);
        end
        
        srcRoot = fullfile(CFG.paths.saveRoot, sampleOut, basePhaseFolder);
        if ~exist(srcRoot, 'dir')
            fprintf('  [skip] %s: не знайдено базове вікно %s\n', sampleLabel, basePhaseFolder);
            continue;
        end
        
        fprintf('\n--- sample: %s ---\n', sampleLabel);
        
        % Проходимо по вікнах 2..numWindows
        for k = 2:CFG.phase.numWindows
            tgtPhaseFolder = tp_phase_folder_name(CFG, k);
            tgtRoot = fullfile(CFG.paths.saveRoot, sampleOut, tgtPhaseFolder);
            fprintf('  Нарізаю: %s ...\n', tgtPhaseFolder);
            
            if ~exist(tgtRoot, 'dir'); mkdir(tgtRoot); end
            
            matFiles = get_all_result_mats(srcRoot);
            rowsCell = {};
            
            for m = 1:numel(matFiles)
                srcMat = matFiles{m};
                relPath = strrep(srcMat, [srcRoot filesep], '');
                tgtMat = fullfile(tgtRoot, relPath);
                
                tgtDir = fileparts(tgtMat);
                if ~exist(tgtDir, 'dir'); mkdir(tgtDir); end
                
                Sload = load(srcMat);
                if isfield(Sload, 'R')
                    R = Sload.R;
                    varName = 'R';
                elseif isfield(Sload, 'Rd')
                    R = Sload.Rd;
                    varName = 'Rd';
                else
                    continue;
                end
                
                % Накладаємо нову симетричну маску!
                [Rmasked, ~] = tp_phase_window_result(R, CFG, k);
                
                if strcmp(varName, 'R')
                    R = Rmasked;
                    save(tgtMat, 'R', '-v7.3');
                    RdForAnalytics = R;
                else
                    Rd = Rmasked;
                    save(tgtMat, 'Rd', '-v7.3');
                    RdForAnalytics = Rd;
                end
                
                % Парсимо algo, dir, step
                parts = strsplit(relPath, filesep);
                algo = parts{1};
                direction = 'XY';
                step = 1;
                
                if strcmpi(algo, 'generalized') || strcmpi(algo, 'XY')
                    stepStr = parts{2};
                    step = sscanf(stepStr, 'step_%d');
                else
                    direction = parts{2};
                    stepStr = parts{3};
                    step = sscanf(stepStr, 'step_%d');
                end
                
                ctx_phase_deg = round(U(k)/pi*180);
                newRows = tp_analytics_rows_for_result(RdForAnalytics, sampleName, example, algo, direction, step, k, ctx_phase_deg, CFG);
                rowsCell = [rowsCell, newRows];
                
                % Малюємо графіки
                tp_visualize(RdForAnalytics, CFG);
            end
            
            % Дописуємо аналітику
            if ~isempty(rowsCell)
                tp_analytics_append_rows(CFG, rowsCell);
            end
        end
        
        % Тренд по всьому зразку
        tp_phase_trend(CFG, sampleName, example);
    end
end
fprintf('\n=== Готово! Усі вікна перенарізані ===\n');
end

function mats = get_all_result_mats(dirPath)
    mats = {};
    files = dir(fullfile(dirPath, '**', 'result.mat'));
    for i = 1:numel(files)
        mats{end+1} = fullfile(files(i).folder, files(i).name);
    end
end
