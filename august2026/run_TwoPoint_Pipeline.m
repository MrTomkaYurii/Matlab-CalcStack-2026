function run_TwoPoint_Pipeline(cfgOverride)
% RUN_TWOPOINT_PIPELINE  Головна точка входу двоточкового фреймворку.
%   Використання:
%       run_TwoPoint_Pipeline                 % бере config/cfg_TwoPoint
%       run_TwoPoint_Pipeline(myCFG)          % бере власну структуру CFG
%
%   Для кожного зразка й кожного прикладу:
%       1) завантажує (або синтезує) поляризаційні зображення (ПОВНІ,
%          без жодної фазової маски),
%       2) якщо CFG.phase.enable і CFG.phase.target = 'field' (типово) —
%          для КОЖНОГО фазового вікна k (або лише CFG.phase.only) відбирає
%          ПОЛЕ: tp_phase_window обнуляє (NaN) пікселі, де phi_xy^(w) =
%          arg Ey^(w) - arg Ex^(w) поза [0, U_k], окремо для кожного
%          освітлення w (стаття, рівн. 20, п. 6–7), і ВЖЕ НА ЦЬОМУ полі
%          рахує всі алгоритми (16 елементів f_ik, усі напрями/кроки),
%       3) зберігає phase_XX/algo/.../result.mat.
%          CFG.phase.target = 'element' — стара (17.09) схема: f_ik рахуються
%          один раз, а вікно ріже готовий f_ik за власним arg (не відповідає
%          статті, лишена лише для відтворення старих результатів).
%       4) будує всі увімкнені подання (maps/sections/wavelet/...) і
%          текстову таблицю статистичних моментів для КОЖНОГО вікна.
%   Щойно зразок (усі приклади) дорахований — одразу збирає його дані для
%   Горського (tp_collect_sample_for_horsky, Етап 3 ТЗ), без ручного
%   запуску run_TwoPoint_CollectForHorsky.
%
%   Чому маска на ПОЛІ, а не на готовому f_ik: у статті фазова селекція —
%   відбір комплексно-амплітудного поля за phi_xy, а двоточкове сканування
%   виконується «для каждой частичной фазовой выборки» поля. Обрізання
%   готового f_ik за власним arg штучно звужує розподіл Arg до ширини вікна.
%
%   Усім керує CFG (config/cfg_TwoPoint.m) — розширюйте саме там.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), genpath(fullfile(here,'core')), ...
        fullfile(here,'io'),     fullfile(here,'viz'), fullfile(here,'simulation'), ...
        fullfile(here,'analysis_ММ'));

if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end
tp_check_config(CFG);   % рання перевірка конфігу (fail-fast із ясним текстом)

fprintf('=== Two-point pipeline ===\n');
fprintf('source = %s | crop = %d x %d | algorithms = {%s}\n', ...
        CFG.source, CFG.crop.size, CFG.crop.size, strjoin(CFG.algorithms, ', '));

phaseOn = isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable;
phaseTarget = 'field';
if phaseOn && isfield(CFG.phase,'target') && ~isempty(CFG.phase.target), phaseTarget = lower(CFG.phase.target); end
phaseList = [];
if phaseOn
    phaseList = 1:CFG.phase.numWindows;
    if isfield(CFG.phase,'only') && ~isempty(CFG.phase.only), phaseList = CFG.phase.only(:).'; end
    if strcmp(phaseTarget,'field')
        maskMode = 'perIllumination';
        if isfield(CFG.phase,'maskMode') && ~isempty(CFG.phase.maskMode), maskMode = CFG.phase.maskMode; end
        fprintf('phase windows {%s} з %d: маска на ПОЛІ (%s), phi_xy в [0, U_k] (U_k: [0,2pi] .. [0,%.3gpi])\n', ...
                num2str(phaseList), CFG.phase.numWindows, maskMode, CFG.phase.upperMin/pi);
    else
        fprintf('phase windows {%s} з %d: per-element arg(f_ik) (стара схема 17.09)\n', ...
                num2str(phaseList), CFG.phase.numWindows);
    end
end

% Для 'real' і 'mat' обробляються ВСІ підтеки з CFG.paths.examples на кожен
% зразок (напр. {'zrazok_1','zrazok_2'} чи {'1','2','3'}); для 'synthetic'
% підтек немає взагалі.
examplesList = {''};
if any(strcmpi(CFG.source,{'real','mat'})) && isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
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
            sampleOut   = fullfile(sampleName, example);  % напр. "Мозг\1"
            loadArgs    = {CFG, sampleName, example};
        end
        fprintf('\n--- sample: %s ---\n', sampleLabel);

        try
            [IMG, loadWarnings] = tp_load_images(loadArgs{:});       % крок 1: дані
        catch ME
            fprintf(2, '  [skip sample] %s: %s\n', sampleLabel, ME.message);
            continue;                                % не змогли завантажити — до наступної пари
        end
        if ~isempty(loadWarnings)
            % Биті/нульові канали НЕ зупиняють розрахунок (за рішенням
            % користувача — переголовити ці зразки неможливо), але мають
            % бути явно видимі: у консоль і окремим файлом у теку зразка.
            fprintf(2, '  [data warning] %s: %d канал(и) биті — див. data_quality_warning.txt\n', ...
                    sampleLabel, numel(loadWarnings));
            outDirW = fullfile(CFG.paths.saveRoot, sampleOut);
            if ~exist(outDirW,'dir'); mkdir(outDirW); end
            fid = fopen(fullfile(outDirW,'data_quality_warning.txt'), 'w', 'n', 'UTF-8');
            fprintf(fid, 'УВАГА: частина вхідних .mat-каналів для %s НЕ комплексна\n', sampleLabel);
            fprintf(fid, '(суцільні нулі — сира голограма без інтерференційних смуг).\n');
            fprintf(fid, 'Завантажено як 0+0i і пораховано як є, за явним рішенням користувача.\n');
            fprintf(fid, 'Результати для цього прикладу МОЖУТЬ бути фізично неповними\n');
            fprintf(fid, '(відсутній внесок відповідної компоненти поля для цього освітлення).\n\n');
            for wi = 1:numel(loadWarnings)
                fprintf(fid, '  - %s\n', loadWarnings{wi});
            end
            fclose(fid);
        end

        if ~phaseOn
            cache = computeAlgorithmsOnce(IMG, CFG, sampleOut, sampleLabel);
            ctx = struct('sample', sampleName, 'example', example, 'phase_index', NaN, 'phase_deg', NaN);
            rowsCell = saveWindowedResults(cache, CFG, sampleOut, sampleLabel, ctx);
            appendAnalytics(CFG, rowsCell, sampleLabel);
            continue;
        end

        U = tp_phase_window_bounds(CFG);

        if strcmp(phaseTarget,'field')
            % --- крок 2: для кожного вікна — відбір ПОЛЯ, потім усі алгоритми на ньому
            for k = phaseList
                phaseFolder = tp_phase_folder_name(CFG, k);
                phaseOut    = fullfile(sampleOut, phaseFolder);
                phaseLabel  = sprintf('%s / %s', sampleLabel, phaseFolder);
                outDir = fullfile(CFG.paths.saveRoot, phaseOut);
                if ~exist(outDir,'dir'); mkdir(outDir); end

                [IMGk, info] = tp_phase_window(IMG, CFG, k);
                writeFieldPhaseInfo(fullfile(outDir,'phase_info.txt'), CFG, info);
                kf = cell2mat(struct2cell(info.keptFrac));
                fprintf('  %s : поле, %s, збережено пікселів %.1f%%..%.1f%%\n', ...
                        phaseFolder, info.mode, 100*min(kf), 100*max(kf));

                cacheK = computeAlgorithmsOnce(IMGk, CFG, phaseOut, phaseLabel);
                ctx = struct('sample', sampleName, 'example', example, ...
                             'phase_index', k, 'phase_deg', round(U(k)/pi*180), 'elementWindow', false);
                rowsCell = saveWindowedResults(cacheK, CFG, phaseOut, phaseLabel, ctx);
                appendAnalytics(CFG, rowsCell, phaseLabel);
            end
            tp_phase_trend(CFG, sampleName, example);
            continue;
        end

        % --- стара схема (target='element'): усі алгоритми ОДИН раз на
        %     повному кадрі, вікно ріже вже ГОТОВИЙ f_ik за власним arg.
        cache = computeAlgorithmsOnce(IMG, CFG, sampleOut, sampleLabel);
        for k = phaseList
            % Межа вікна ПРЯМО в назві теки (частка pi, 2 знаки — щоб не було
            % "соті" на весь екран), і номер попереду — для сортування:
            %   phase_01_[0-2.00pi] ... phase_08_[0-0.25pi]
            % (лейбл — та сама ШИРИНА U_k, що й завжди; фактичний діапазон
            % arg(f_ik) — [0, U_k] (mod 2pi), стягується до 0° — tp_phase_window_element.m)
            phaseFolder  = tp_phase_folder_name(CFG, k);
            phaseOut     = fullfile(sampleOut, phaseFolder);
            phaseLabel   = sprintf('%s / %s', sampleLabel, phaseFolder);

            outDir = fullfile(CFG.paths.saveRoot, phaseOut);
            if ~exist(outDir,'dir'); mkdir(outDir); end

            ctx = struct('sample', sampleName, 'example', example, ...
                         'phase_index', k, 'phase_deg', round(U(k)/pi*180));
            [rowsCell, keptFracByAlgo] = saveWindowedResults(cache, CFG, phaseOut, phaseLabel, ctx);
            writePhaseInfo(fullfile(outDir,'phase_info.txt'), CFG, k, keptFracByAlgo);
            fprintf('  %s : per-element arg-вікно [0, %.3fpi]\n', phaseFolder, U(k)/pi);

            appendAnalytics(CFG, rowsCell, phaseLabel);
        end

        tp_phase_trend(CFG, sampleName, example);   % тренд статистики по всіх k, після факту
    end

    % Зразок повністю дорахований (усі приклади) -> одразу зібрати дані
    % для Горського (Етап 3 ТЗ: "по мірі обчислення надсилати"), без
    % ручного запуску run_TwoPoint_CollectForHorsky. Не рахує нічого
    % заново — лише пакує вже збережені result.mat цього зразка.
    %
    % Збирач пакує алгоритми зі списку CFG.horsky.algorithms
    % ({'orthogonal','generalized','polar','XY'} за замовчуванням). Якщо
    % цього прогону НЕ рахувався жоден із них (напр. CFG.algorithms = {'polar'},
    % а Горський звужений до {'orthogonal'}), збирач пропускаємо: інакше
    % він мовчки перепакував би СТАРІ result.mat з попереднього прогону.
    horskyWanted = {'orthogonal','generalized','polar','XY'};
    if isfield(CFG,'horsky') && isfield(CFG.horsky,'algorithms') && ~isempty(CFG.horsky.algorithms)
        horskyWanted = CFG.horsky.algorithms;
    end
    if any(ismember(lower(CFG.algorithms), lower(horskyWanted)))
        try
            [nFilesOrtho, nFilesGen, nFilesPolar, nFilesXY] = tp_collect_sample_for_horsky(CFG, sampleName);
            if nFilesOrtho > 0
                fprintf('  [Horsky] %s: %d *_orthogonal.mat (по прикладах)\n', sampleName, nFilesOrtho);
            end
            if nFilesGen > 0
                fprintf('  [Horsky] %s: %d *_generalized.mat (по прикладах)\n', sampleName, nFilesGen);
            end
            if nFilesPolar > 0
                fprintf('  [Horsky] %s: %d *_polar.mat (по прикладах)\n', sampleName, nFilesPolar);
            end
            if nFilesXY > 0
                fprintf('  [Horsky] %s: %d *_XY.mat (по прикладах)\n', sampleName, nFilesXY);
            end
        catch ME
            fprintf(2, '  [Horsky fail] %s: %s\n', sampleName, ME.message);
        end
    else
        fprintf('  [Horsky] %s: пропущено — цього прогону не рахувався жоден алгоритм зі списку {%s}\n', ...
                sampleName, strjoin(horskyWanted, ', '));
    end
end

fprintf('\n=== done. Results in: %s ===\n', CFG.paths.saveRoot);
end

% ------------------------------------------------------------------------
function cache = computeAlgorithmsOnce(IMG, CFG, sampleOut, sampleLabel)
% Рахує КОЖЕН алгоритм з CFG.algorithms РІВНО ОДИН РАЗ на ПОВНОМУ
% (немаскованому) IMG — незалежно від того, скільки фазових вікон
% застосовуватиметься пізніше (saveWindowedResults ріже ГОТОВИЙ f_ik).
%
% cache.ortho : R з tp_algo_orthogonal (усі напрями/кроки), або [] —
%               рахується, якщо 'orthogonal' АБО 'XY' у CFG.algorithms
%               (XY-у потрібен ПОВНИЙ, немаскований OX/OY).
% cache.polar : R з tp_algo_polar, або [].
% cache.gen   : struct('step_<d>', R) — по одному R на кожен CFG.gen.steps.

cache = struct('ortho', [], 'polar', [], 'gen', struct());

needOrtho = any(strcmpi(CFG.algorithms,'orthogonal')) || any(strcmpi(CFG.algorithms,'XY'));
if needOrtho
    try
        t = tic;
        cache.ortho = tp_algo_orthogonal(IMG, CFG, sampleOut);
        fprintf('    [orthogonal] computed in %.1f s (повний кадр, без фазової маски)\n', toc(t));
    catch ME
        fprintf(2, '    [fail] %s / orthogonal (розрахунок): %s\n', sampleLabel, ME.message);
    end
end

if any(strcmpi(CFG.algorithms,'polar'))
    try
        t = tic;
        cache.polar = tp_algo_polar(IMG, CFG, sampleOut);
        fprintf('    [polar] computed in %.1f s (повний кадр, без фазової маски)\n', toc(t));
    catch ME
        fprintf(2, '    [fail] %s / polar (розрахунок): %s\n', sampleLabel, ME.message);
    end
end

if any(strcmpi(CFG.algorithms,'generalized'))
    for si = 1:numel(CFG.gen.steps)
        step = CFG.gen.steps(si);
        try
            t = tic;
            R = tp_algo_generalized_run(IMG, CFG, sampleOut, step);
            fprintf('    [generalized step_%d] computed in %.1f s (повний кадр)\n', step, toc(t));
            cache.gen.(sprintf('step_%d', step)) = R;
        catch ME
            fprintf(2, '    [fail] %s / generalized step_%d (розрахунок): %s\n', sampleLabel, step, ME.message);
        end
    end
end
end

% ------------------------------------------------------------------------
function [rowsCell, keptFracByAlgo] = saveWindowedResults(cache, CFG, sampleOut, sampleLabel, ctx)
% Бере кешовані (ОДИН РАЗ пораховані, немасковані) результати й:
%   - якщо CFG.phase.enable і ctx.phase_index не NaN — ріже КОЖЕН елемент
%     КОЖНОГО кешованого результату за ЙОГО ВЛАСНИМ arg (tp_phase_window_
%     result -> tp_phase_window_element), окремо для orthogonal/polar/
%     generalized/XY;
%   - зберігає result.mat у ТІ САМІ шляхи, що й раніше (sampleOut містить
%     фазову підтеку, якщо вона є — викликається так само, як старий
%     runAlgorithms);
%   - малює (tp_visualize) і формує рядки аналітики.
%
% ctx = struct('sample',.., 'example',.., 'phase_index',.., 'phase_deg',..)
% rowsCell       — рядки аналітики (cell of table), для appendAnalytics.
% keptFracByAlgo — struct('orthogonal',...,'polar',...,'generalized',...,'XY',...)
%                  кожен = struct(dir).(elem) = частка збережених пікселів (QC),
%                  або [] якщо алгоритм не рахувався/вікно не накладалось.

rowsCell = {};
keptFracByAlgo = struct('orthogonal', [], 'polar', [], 'generalized', [], 'XY', []);
phaseOn = isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable ...
          && isfield(ctx,'phase_index') && ~isnan(ctx.phase_index) ...
          && ~(isfield(ctx,'elementWindow') && ~ctx.elementWindow);   % поле вже відібране -> f_ik не різати
k = ctx.phase_index;

% ---- orthogonal ----
if ~isempty(cache.ortho) && any(strcmpi(CFG.algorithms,'orthogonal'))
    try
        R = cache.ortho;
        if phaseOn
            [R, kf] = tp_phase_window_result(R, CFG, k);
            keptFracByAlgo.orthogonal = kf;
        end
        for di = 1:numel(R.dirs)
            dirName = R.dirs{di};
            sep = R.sep.(dirName);
            outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'orthogonal', sep.direction, sprintf('step_%d', sep.delta));
            if ~exist(outDir,'dir'); mkdir(outDir); end
            Rd = tp_slice_result_dir(R, dirName);
            save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');
            newRows = tp_analytics_rows_for_result(Rd, ctx.sample, ctx.example, 'orthogonal', sep.direction, ...
                                                    sep.delta, ctx.phase_index, ctx.phase_deg, CFG);
            rowsCell = [rowsCell, newRows]; %#ok<AGROW>
        end
        tp_visualize(R, CFG);
    catch ME
        fprintf(2, '    [fail] %s / orthogonal (вікно/збереження): %s\n', sampleLabel, ME.message);
    end
end

% ---- polar ----
if ~isempty(cache.polar) && any(strcmpi(CFG.algorithms,'polar'))
    try
        R = cache.polar;
        if phaseOn
            [R, kf] = tp_phase_window_result(R, CFG, k);
            keptFracByAlgo.polar = kf;
        end
        for di = 1:numel(R.dirs)
            dirName = R.dirs{di};
            sep = R.sep.(dirName);
            outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'polar', sep.direction, sprintf('step_%d', sep.delta));
            if ~exist(outDir,'dir'); mkdir(outDir); end
            Rd = tp_slice_result_dir(R, dirName);
            save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');
            newRows = tp_analytics_rows_for_result(Rd, ctx.sample, ctx.example, 'polar', sep.direction, ...
                                                    sep.delta, ctx.phase_index, ctx.phase_deg, CFG);
            rowsCell = [rowsCell, newRows]; %#ok<AGROW>
        end
        tp_visualize(R, CFG);
    catch ME
        fprintf(2, '    [fail] %s / polar (вікно/збереження): %s\n', sampleLabel, ME.message);
    end
end

% ---- generalized ----
if any(strcmpi(CFG.algorithms,'generalized'))
    gfn = fieldnames(cache.gen);
    kfAll = struct();
    for gi = 1:numel(gfn)
        step = sscanf(gfn{gi}, 'step_%d');
        try
            R = cache.gen.(gfn{gi});
            if phaseOn
                [R, kf] = tp_phase_window_result(R, CFG, k);
                kfAll.(gfn{gi}) = kf;
            end
            outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'generalized', sprintf('step_%d', step));
            if ~exist(outDir,'dir'); mkdir(outDir); end
            save(fullfile(outDir,'result.mat'), 'R', '-v7.3');
            newRows = tp_analytics_rows_for_result(R, ctx.sample, ctx.example, 'generalized', 'XY', ...
                                                    step, ctx.phase_index, ctx.phase_deg, CFG);
            rowsCell = [rowsCell, newRows]; %#ok<AGROW>
            tp_visualize(R, CFG);
        catch ME
            fprintf(2, '    [fail] %s / generalized step_%d (вікно/збереження): %s\n', sampleLabel, step, ME.message);
        end
    end
    keptFracByAlgo.generalized = kfAll;
end

% ---- XY: ЗВЕДЕНА OX+OY з КЕШОВАНОГО немаскованого orthogonal (у пам'яті) —
%      НЕ з диску, інакше читала б уже провіконений (ЧУЖИМ, per-element,
%      критерієм) orthogonal.result.mat цього ж k, і сума на пікселях, де
%      один з рукавів (OX чи OY) випав з СВОГО вікна, вийшла б частковою,
%      а не істинним OX+OY. tp_algo_XY.m тепер приймає RorthoCache. ----
if any(strcmpi(CFG.algorithms,'XY'))
    kfAll = struct();
    for si = 1:numel(CFG.ortho.steps)
        step = CFG.ortho.steps(si);
        try
            R = tp_algo_XY([], CFG, sampleOut, step, cache.ortho);
            if phaseOn
                [R, kf] = tp_phase_window_result(R, CFG, k);
                kfAll.(sprintf('step_%d', step)) = kf;
            end
            outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'XY', sprintf('step_%d', step));
            if ~exist(outDir,'dir'); mkdir(outDir); end
            save(fullfile(outDir,'result.mat'), 'R', '-v7.3');
            newRows = tp_analytics_rows_for_result(R, ctx.sample, ctx.example, 'XY', 'XY', ...
                                                    step, ctx.phase_index, ctx.phase_deg, CFG);
            rowsCell = [rowsCell, newRows]; %#ok<AGROW>
            tp_visualize(R, CFG);
        catch ME
            fprintf(2, '    [fail] %s / XY step_%d: %s\n', sampleLabel, step, ME.message);
        end
    end
    keptFracByAlgo.XY = kfAll;
end
end

% ------------------------------------------------------------------------
function appendAnalytics(CFG, rowsCell, label)
% Дописує щойно пораховані рядки аналітики (етап 1) одразу, наживо —
% без окремого пізнішого перерахунку зведень у run_TwoPoint_Analytics.m.
if isempty(rowsCell), return; end
try
    tp_analytics_append_rows(CFG, rowsCell);
catch ME
    fprintf(2, '    [analytics fail] %s: %s\n', label, ME.message);
end
end

% ------------------------------------------------------------------------
function writeFieldPhaseInfo(fname, CFG, info)
% Супровід фазового вікна для схеми «маска на полі» (tp_phase_window.m).
fid = fopen(fname, 'w', 'n', 'UTF-8');
fprintf(fid, 'Фазова вибірка %d з %d\n', info.index, CFG.phase.numWindows);
fprintf(fid, 'Критерій: phi_xy = arg Ey - arg Ex ПОЛЯ, до розрахунку f_ik (tp_phase_window.m), режим %s\n', info.mode);
fprintf(fid, 'Вікно: [%.6f, %.6f] рад  ([%.4f, %.4f] * pi)\n', info.lower, info.upper, info.lower/pi, info.upper/pi);
fprintf(fid, '\nЗбережено пікселів поля (keptFrac), по освітленню:\n');
pols = fieldnames(info.keptFrac);
for p = 1:numel(pols)
    fprintf(fid, '  %-7s : %.1f%%\n', pols{p}, 100*info.keptFrac.(pols{p}));
end
fclose(fid);
end

% ------------------------------------------------------------------------
function writePhaseInfo(fname, CFG, k, keptFracByAlgo)
% Короткий текстовий супровід фазового вікна k — межі arg (per-element,
% ОДНАКОВІ для всіх елементів/алгоритмів, tp_phase_window_element.m) і
% частка збережених пікселів КОЖНОГО елемента (для QC: чи не забагато
% NaN на вузьких вікнах) — на відміну від старої версії (один спільний
% deltaRef-QC на весь зразок), тепер keptFrac різний по елементах.
U = tp_phase_window_bounds(CFG);
lower = 0; upper = U(k);

fid = fopen(fname, 'w', 'n', 'UTF-8');
fprintf(fid, 'Фазова вибірка %d з %d\n', k, CFG.phase.numWindows);
fprintf(fid, 'Критерій: власний arg(f_ik) КОЖНОГО елемента (tp_phase_window_element.m)\n');
fprintf(fid, 'Вікно: [%.6f, %.6f] рад  ([%.4f, %.4f] * pi)\n', lower, upper, lower/pi, upper/pi);
fprintf(fid, '\nЗбережено пікселів (keptFrac), по алгоритму/напряму/елементу:\n');

algoNames = fieldnames(keptFracByAlgo);
for ai = 1:numel(algoNames)
    algoName = algoNames{ai};
    kf = keptFracByAlgo.(algoName);
    if isempty(kf), continue; end
    fprintf(fid, '  %s:\n', algoName);
    % kf: struct(dir).(elem)=frac  АБО  struct(step_d).(dir).(elem)=frac (generalized/XY)
    L1 = fieldnames(kf);
    for i1 = 1:numel(L1)
        v1 = kf.(L1{i1});
        if isstruct(v1) && ~isfield(v1, 'keptFrac') && ~isnumeric(v1)
            L2 = fieldnames(v1);
            if ~isempty(L2) && isnumeric(v1.(L2{1}))
                % struct(dir).(elem)=frac
                for i2 = 1:numel(L2)
                    fprintf(fid, '    %s / %s : %.1f%%\n', L1{i1}, L2{i2}, 100*v1.(L2{i2}));
                end
            else
                % struct(step).(dir).(elem)=frac
                for i2 = 1:numel(L2)
                    d2 = v1.(L2{i2});
                    e2 = fieldnames(d2);
                    for i3 = 1:numel(e2)
                        fprintf(fid, '    %s / %s / %s : %.1f%%\n', L1{i1}, L2{i2}, e2{i3}, 100*d2.(e2{i3}));
                    end
                end
            end
        end
    end
end
fclose(fid);
end
