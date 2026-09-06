function run_TwoPoint_FillMissing(cfgOverride)
% RUN_TWOPOINT_FILLMISSING  Знаходить і дораховує ЛИШЕ те, чого бракує на
%   диску (порівняно з тим, що мало б бути за поточним CFG: усі зразки x
%   приклади x фазові вікна x алгоритми x кроки), і НІЧОГО не чіпає з уже
%   готового. Не змінює й не залежить від run_TwoPoint_Pipeline.m — окремий,
%   самодостатній файл: можна видалити після використання без жодних
%   наслідків для решти конвеєра.
%
%   Навіщо: якщо конфіг мінявся під час серії розрахунків (напр. додали
%   крок чи алгоритм пізніше), деякі комбінації лишаються непорахованими —
%   цей скрипт знаходить саме їх і рахує тільки їх, а не все спочатку.
%
%   Для orthogonal: якщо для фазового вікна бракує ХОЧА Б ОДНОГО напряму/
%   кроку — перераховується ВЕСЬ tp_algo_orthogonal для цього вікна (він
%   і так рахує всі напрями/кроки за один виклик) і перезаписуються всі
%   підтеки напрям\крок (уже готові — тим самим значенням, нешкідливо).
%   Для generalized: кожен крок незалежний — рахуються ТІЛЬКИ відсутні
%   кроки, наявні не займаються.
%
%   Після збереження result.mat — та сама аналітика (Крок 1) і ті самі
%   візуалізації (tp_visualize), що й у основному пайплайні, щоб
%   result.mat/аналітика/картинки були повністю сумісні з рештою.
%
%   Використання:
%       run_TwoPoint_FillMissing            % бере config/cfg_TwoPoint
%       run_TwoPoint_FillMissing(myCFG)     % власна структура CFG

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), genpath(fullfile(here,'core')), ...
        fullfile(here,'io'),     fullfile(here,'viz'), fullfile(here,'simulation'), ...
        fullfile(here,'analysis'));

if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end
tp_check_config(CFG);

phaseOn = isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable;
numK = 1; if phaseOn, numK = CFG.phase.numWindows; end
if phaseOn, U = tp_phase_window_bounds(CFG); end

examplesList = {''};
if any(strcmpi(CFG.source,{'real','mat'})) && isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
    examplesList = CFG.paths.examples;
end

directions = {'OX','OY'};
if isfield(CFG.ortho,'directions') && ~isempty(CFG.ortho.directions)
    directions = CFG.ortho.directions;
end

fprintf('=== Пошук прогалин ===\n');
plan = struct('sampleName',{},'example',{},'k',{},'needOrtho',{},'needGenSteps',{},'needPolar',{});

for s = 1:numel(CFG.samples)
    sampleName = CFG.samples{s};
    for ei = 1:numel(examplesList)
        example = examplesList{ei};
        if isempty(example), sampleOut = sampleName; else, sampleOut = fullfile(sampleName, example); end

        for k = 1:numK
            if phaseOn
                phaseOut = fullfile(sampleOut, tp_phase_folder_name(CFG, k));
            else
                phaseOut = sampleOut;
            end

            needOrtho = false;
            if any(strcmpi(CFG.algorithms,'orthogonal'))
                for d = 1:numel(directions)
                    for si = 1:numel(CFG.ortho.steps)
                        f = fullfile(CFG.paths.saveRoot, phaseOut, 'orthogonal', directions{d}, ...
                                     sprintf('step_%d', CFG.ortho.steps(si)), 'result.mat');
                        if ~isfile(f), needOrtho = true; end
                    end
                end
            end

            needGenSteps = [];
            if any(strcmpi(CFG.algorithms,'generalized'))
                for si = 1:numel(CFG.gen.steps)
                    step = CFG.gen.steps(si);
                    f = fullfile(CFG.paths.saveRoot, phaseOut, 'generalized', sprintf('step_%d', step), 'result.mat');
                    if ~isfile(f), needGenSteps(end+1) = step; end %#ok<AGROW>
                end
            end

            % polar: tp_algo_polar рахує всі напрями (PERP/OX/OY) за один виклик,
            % як orthogonal -> досить перевірити ЄДИНУ карту PERP на кожен радіус
            % rho (OX/OY можуть бути відсутні за конфігом — 90 не кратне angleStep —
            % і не мають запускати нескінченний дорахунок).
            needPolar = false;
            if any(strcmpi(CFG.algorithms,'polar')) && isfield(CFG,'polar')
                for si = 1:numel(CFG.polar.radii)
                    f = fullfile(CFG.paths.saveRoot, phaseOut, 'polar', 'PERP', ...
                                 sprintf('step_%d', CFG.polar.radii(si)), 'result.mat');
                    if ~isfile(f), needPolar = true; end
                end
            end

            if needOrtho || ~isempty(needGenSteps) || needPolar
                plan(end+1) = struct('sampleName',sampleName, 'example',example, 'k',k, ...
                                      'needOrtho',needOrtho, 'needGenSteps',needGenSteps, ...
                                      'needPolar',needPolar); %#ok<AGROW>
            end
        end
    end
end

if isempty(plan)
    fprintf('Прогалин не знайдено — усе, що мало б бути за поточним CFG, вже є на диску.\n');
    return;
end

fprintf('Знайдено %d прогалин (зразок x приклад x фазове вікно):\n', numel(plan));
for i = 1:numel(plan)
    genTxt = 'нічого';
    if ~isempty(plan(i).needGenSteps)
        genTxt = ['steps ' mat2str(plan(i).needGenSteps)];
    end
    fprintf('  %s / %s / k=%d : orthogonal=%d, generalized=%s, polar=%d\n', ...
            plan(i).sampleName, plan(i).example, plan(i).k, plan(i).needOrtho, genTxt, plan(i).needPolar);
end

% ---- дорахувати: групуємо по (sampleName,example), щоб не перечитувати IMG ----
% (без struct2table: needGenSteps різної довжини по рядках зламав би її)
pairKeys = strings(1, numel(plan));
for i = 1:numel(plan)
    pairKeys(i) = string(plan(i).sampleName) + "|" + string(plan(i).example);
end
uniquePairs = unique(pairKeys);
for p = 1:numel(uniquePairs)
    parts = split(uniquePairs(p), '|');
    sampleName = char(parts(1)); example = char(parts(2));
    if isempty(example), sampleOut = sampleName; sampleLabel = sampleName; loadArgs = {CFG, sampleName};
    else, sampleOut = fullfile(sampleName, example); sampleLabel = sprintf('%s / %s', sampleName, example);
          loadArgs = {CFG, sampleName, example};
    end

    idx = find(strcmp({plan.sampleName}, sampleName) & strcmp({plan.example}, example));
    fprintf('\n--- дораховую: %s (%d фазових вікон) ---\n', sampleLabel, numel(idx));

    try
        [IMG, ~] = tp_load_images(loadArgs{:});
    catch ME
        fprintf(2, '  [skip] %s: не вдалось завантажити (%s)\n', sampleLabel, ME.message);
        continue;
    end

    for ii = idx
        it = plan(ii);
        if phaseOn
            [IMGk, ~] = tp_phase_window(IMG, CFG, it.k);
            phaseFolder = tp_phase_folder_name(CFG, it.k);
            phaseOut = fullfile(sampleOut, phaseFolder);
            phaseDeg = round(U(it.k)/pi*180);
        else
            IMGk = IMG; phaseOut = sampleOut; phaseDeg = NaN;
        end
        ctx = struct('sample', sampleName, 'example', example, 'phase_index', it.k, 'phase_deg', phaseDeg);

        if it.needOrtho
            try
                t = tic;
                R = tp_algo_orthogonal(IMGk, CFG, sampleOut);
                fprintf('    [orthogonal] %s / k=%d : computed in %.1f s\n', sampleLabel, it.k, toc(t));
                for di = 1:numel(R.dirs)
                    dirName = R.dirs{di};
                    sep = R.sep.(dirName);
                    outDir = fullfile(CFG.paths.saveRoot, phaseOut, 'orthogonal', sep.direction, sprintf('step_%d', sep.delta));
                    if ~exist(outDir,'dir'); mkdir(outDir); end
                    Rd = tp_slice_result_dir(R, dirName);
                    save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');
                    rows = tp_analytics_rows_for_result(Rd, ctx.sample, ctx.example, 'orthogonal', ...
                                                         sep.direction, sep.delta, ctx.phase_index, ctx.phase_deg, CFG);
                    tryAppend(CFG, rows, sampleLabel);
                end
                tp_visualize(R, CFG);
            catch ME
                fprintf(2, '    [fail] %s / orthogonal k=%d: %s\n', sampleLabel, it.k, ME.message);
            end
        end

        if it.needPolar
            try
                t = tic;
                R = tp_algo_polar(IMGk, CFG, sampleOut);
                fprintf('    [polar] %s / k=%d : computed in %.1f s\n', sampleLabel, it.k, toc(t));
                for di = 1:numel(R.dirs)
                    dirName = R.dirs{di};
                    sep = R.sep.(dirName);
                    outDir = fullfile(CFG.paths.saveRoot, phaseOut, 'polar', sep.direction, sprintf('step_%d', sep.delta));
                    if ~exist(outDir,'dir'); mkdir(outDir); end
                    Rd = tp_slice_result_dir(R, dirName);
                    save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');
                    rows = tp_analytics_rows_for_result(Rd, ctx.sample, ctx.example, 'polar', ...
                                                         sep.direction, sep.delta, ctx.phase_index, ctx.phase_deg, CFG);
                    tryAppend(CFG, rows, sampleLabel);
                end
                tp_visualize(R, CFG);
            catch ME
                fprintf(2, '    [fail] %s / polar k=%d: %s\n', sampleLabel, it.k, ME.message);
            end
        end

        for si = 1:numel(it.needGenSteps)
            step = it.needGenSteps(si);
            try
                t = tic;
                R = tp_algo_generalized(IMGk, CFG, sampleOut, step);
                fprintf('    [generalized step_%d] %s / k=%d : computed in %.1f s\n', step, sampleLabel, it.k, toc(t));
                outDir = fullfile(CFG.paths.saveRoot, phaseOut, 'generalized', sprintf('step_%d', step));
                if ~exist(outDir,'dir'); mkdir(outDir); end
                save(fullfile(outDir,'result.mat'), 'R', '-v7.3');
                rows = tp_analytics_rows_for_result(R, ctx.sample, ctx.example, 'generalized', ...
                                                     'XY', step, ctx.phase_index, ctx.phase_deg, CFG);
                tryAppend(CFG, rows, sampleLabel);
                tp_visualize(R, CFG);
            catch ME
                fprintf(2, '    [fail] %s / generalized step_%d k=%d: %s\n', sampleLabel, step, it.k, ME.message);
            end
        end
    end
end

fprintf('\n=== Прогалини дораховано. Онови Горського/аналітику окремо, якщо треба ===\n');
fprintf('  run_TwoPoint_CollectForHorsky\n  run_TwoPoint_Analytics\n');
end

% ------------------------------------------------------------------------
function tryAppend(CFG, rows, label)
if isempty(rows), return; end
try
    tp_analytics_append_rows(CFG, rows);
catch ME
    fprintf(2, '    [analytics fail] %s: %s\n', label, ME.message);
end
end
