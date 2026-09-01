function run_TwoPoint_Pipeline(cfgOverride)
% RUN_TWOPOINT_PIPELINE  Головна точка входу двоточкового фреймворку.
%   Використання:
%       run_TwoPoint_Pipeline                 % бере config/cfg_TwoPoint
%       run_TwoPoint_Pipeline(myCFG)          % бере власну структуру CFG
%
%   Для кожного зразка й кожного обраного алгоритму:
%       1) завантажує (або синтезує) поляризаційні зображення,
%       2) обчислює 16 комплексних елементів Мюллера f_ik,
%       3) зберігає сиру структуру результату (result.mat),
%       4) будує всі увімкнені подання (maps/sections/wavelet),
%          пропускаючи розподіли, що не пройшли контроль якості.
%
%   Усім керує CFG (config/cfg_TwoPoint.m) — розширюйте саме там.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), fullfile(here,'core'), ...
        fullfile(here,'io'),     fullfile(here,'viz'), fullfile(here,'simulation'));

if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end
tp_check_config(CFG);   % рання перевірка конфігу (fail-fast із ясним текстом)

fprintf('=== Two-point pipeline ===\n');
fprintf('source = %s | crop = %d x %d | algorithms = {%s}\n', ...
        CFG.source, CFG.crop.size, CFG.crop.size, strjoin(CFG.algorithms, ', '));

% Для 'real' обробляються ВСІ підтеки з CFG.paths.examples на кожен зразок
% (напр. {'zrazok_1','zrazok_2'}); для 'synthetic' підтек немає взагалі.
examplesList = {''};
if strcmpi(CFG.source,'real') && isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
    examplesList = CFG.paths.examples;
end

for s = 1:numel(CFG.samples)
    sampleName = CFG.samples{s};

    for ei = 1:numel(examplesList)
        example = examplesList{ei};
        if isempty(example)
            sampleLabel = sampleName;                    % для друку в консоль
            sampleOut   = sampleName;                     % для тек результатів (= R.sample)
            loadArgs    = {CFG, sampleName};
        else
            sampleLabel = sprintf('%s / %s', sampleName, example);
            sampleOut   = fullfile(sampleName, example);  % напр. "Печінка\zrazok_1"
            loadArgs    = {CFG, sampleName, example};
        end
        fprintf('\n--- sample: %s ---\n', sampleLabel);

        try
            IMG = tp_load_images(loadArgs{:});       % крок 1: дані
        catch ME
            fprintf(2, '  [skip sample] %s: %s\n', sampleLabel, ME.message);
            continue;                                % не змогли завантажити — до наступної пари
        end

        for a = 1:numel(CFG.algorithms)
            algo = CFG.algorithms{a};

            if strcmpi(algo, 'generalized')
                % ПОКРОКОВО: порахував крок -> зберіг -> намалював -> наступний крок.
                % Так проміжні кроки не губляться, навіть якщо прогін перервати
                % (напр. кинути багато кроків на ніч і зупинити посередині).
                for si = 1:numel(CFG.gen.steps)
                    step = CFG.gen.steps(si);
                    try
                        t = tic;
                        R = tp_algo_generalized(IMG, CFG, sampleOut, step);
                        fprintf('  [generalized step_%d] computed in %.1f s\n', step, toc(t));

                        outDir = fullfile(CFG.paths.saveRoot, sampleOut, algo, sprintf('step_%d', step));
                        if ~exist(outDir,'dir'); mkdir(outDir); end
                        save(fullfile(outDir,'result.mat'), 'R', '-v7.3');

                        tp_visualize(R, CFG);
                    catch ME
                        fprintf(2, '  [fail] %s / generalized step_%d: %s\n', sampleLabel, step, ME.message);
                    end
                end
                continue;
            end

            try
                t = tic;
                switch lower(algo)                   % крок 2: обчислення f_ik
                    case 'orthogonal', R = tp_algo_orthogonal(IMG, CFG, sampleOut);
                    otherwise
                        warning('run_TwoPoint_Pipeline:algo', 'Невідомий алгоритм "%s" — пропущено.', algo);
                        continue;
                end
                fprintf('  [%s] computed in %.1f s\n', algo, toc(t));

                outDir = fullfile(CFG.paths.saveRoot, sampleOut, algo);   % крок 3: зберегти
                if ~exist(outDir,'dir'); mkdir(outDir); end
                save(fullfile(outDir,'result.mat'), 'R', '-v7.3');

                tp_visualize(R, CFG);                % крок 4: візуалізація
            catch ME
                fprintf(2, '  [fail] %s / %s: %s\n', sampleLabel, algo, ME.message);
            end
        end
    end
end

fprintf('\n=== done. Results in: %s ===\n', CFG.paths.saveRoot);
end
