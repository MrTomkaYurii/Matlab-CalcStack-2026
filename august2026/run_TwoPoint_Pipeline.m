function run_TwoPoint_Pipeline(cfgOverride)
% RUN_TWOPOINT_PIPELINE  Головна точка входу двоточкового фреймворку.
%   Використання:
%       run_TwoPoint_Pipeline                 % бере config/cfg_TwoPoint
%       run_TwoPoint_Pipeline(myCFG)          % бере власну структуру CFG
%
%   Для кожного зразка, кожного прикладу і (якщо CFG.phase.enable) кожної
%   з CFG.phase.numWindows фазових вибірок (Етап 1 ТЗ):
%       1) завантажує (або синтезує) поляризаційні зображення,
%       1b) застосовує фазове вікно k (tp_phase_window) — пікселі поза
%           [0, U_k] опорної фази стають NaN в Ex,Ey УСІХ освітлень,
%       2) обчислює 16 комплексних елементів Мюллера f_ik,
%       3) зберігає сиру структуру результату (result.mat),
%       4) будує всі увімкнені подання (maps/sections/wavelet/...) і
%          текстову таблицю статистичних моментів,
%          пропускаючи розподіли, що не пройшли контроль якості.
%   Щойно зразок (усі приклади) дорахований — одразу збирає його дані для
%   Горського (tp_collect_sample_for_horsky, Етап 3 ТЗ), без ручного
%   запуску run_TwoPoint_CollectForHorsky.
%
%   Усім керує CFG (config/cfg_TwoPoint.m) — розширюйте саме там.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), genpath(fullfile(here,'core')), ...
        fullfile(here,'io'),     fullfile(here,'viz'), fullfile(here,'simulation'), ...
        fullfile(here,'analysis'));

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
if phaseOn
    fprintf('phase windows = %d (refPol=%s, [0,2pi] .. [0,%.3gpi])\n', ...
            CFG.phase.numWindows, CFG.phase.refPol, CFG.phase.upperMin/pi);
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
            ctx = struct('sample', sampleName, 'example', example, 'phase_index', 1, 'phase_deg', NaN);
            rowsCell = runAlgorithms(IMG, CFG, sampleOut, sampleLabel, ctx);
            appendAnalytics(CFG, rowsCell, sampleLabel);
            continue;
        end

        U = tp_phase_window_bounds(CFG);
        for k = 1:CFG.phase.numWindows
            [IMGk, info] = tp_phase_window(IMG, CFG, k);
            % Межа вікна ПРЯМО в назві теки (частка pi, 2 знаки — щоб не було
            % "соті" на весь екран), і номер попереду — для сортування:
            %   phase_01_[0-2.00pi] ... phase_08_[0-0.25pi]
            phaseFolder  = tp_phase_folder_name(CFG, k);
            phaseOut     = fullfile(sampleOut, phaseFolder);
            phaseLabel   = sprintf('%s / %s', sampleLabel, phaseFolder);
            fprintf('  %s : keptFrac=%.3f\n', phaseFolder, info.keptFrac);

            outDir = fullfile(CFG.paths.saveRoot, phaseOut);
            if ~exist(outDir,'dir'); mkdir(outDir); end
            writePhaseInfo(fullfile(outDir,'phase_info.txt'), CFG, info);
            try
                viz_phase_mask(info.deltaRef, info.mask, info, sampleLabel, CFG, outDir);
            catch ME
                fprintf(2, '    [viz fail] phase_mask: %s\n', ME.message);
            end

            ctx = struct('sample', sampleName, 'example', example, ...
                         'phase_index', k, 'phase_deg', round(U(k)/pi*180));
            rowsCell = runAlgorithms(IMGk, CFG, phaseOut, phaseLabel, ctx);
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
function rowsCell = runAlgorithms(IMG, CFG, sampleOut, sampleLabel, ctx)
% Рахує й зберігає всі увімкнені алгоритми (CFG.algorithms) для ОДНОГО
% вже завантаженого (і, можливо, фазово-замаскованого) IMG. Просто:
% порахував -> зберіг -> намалював -> порахував аналітику (Крок 1, з
% УЖЕ готового R/Rd — без перечитування result.mat пізніше). Без резюме/
% домерджування — якщо треба перерахувати, видаляється відповідна тека
% результатів і пайплайн запускається заново.
%
% ctx = struct('sample',.., 'example',.., 'phase_index',.., 'phase_deg',..)
% rowsCell — рядки аналітики (cell of table), для appendAnalytics.

rowsCell = {};
% 'XY' збирається з orthogonal-результату -> завжди обробляємо його ПІСЛЯ
% решти (зокрема після 'orthogonal'), незалежно від порядку в CFG.algorithms.
algoOrder = [CFG.algorithms(~strcmpi(CFG.algorithms,'XY')), CFG.algorithms(strcmpi(CFG.algorithms,'XY'))];
for a = 1:numel(algoOrder)
    algo = algoOrder{a};

    if strcmpi(algo, 'generalized')
        % ПОКРОКОВО: порахував крок -> зберіг -> намалював -> наступний крок.
        for si = 1:numel(CFG.gen.steps)
            step = CFG.gen.steps(si);
            try
                t = tic;
                R = tp_algo_generalized(IMG, CFG, sampleOut, step);
                fprintf('    [generalized step_%d] computed in %.1f s\n', step, toc(t));

                outDir = fullfile(CFG.paths.saveRoot, sampleOut, algo, sprintf('step_%d', step));
                if ~exist(outDir,'dir'); mkdir(outDir); end
                save(fullfile(outDir,'result.mat'), 'R', '-v7.3');

                tp_visualize(R, CFG);
                newRows = tp_analytics_rows_for_result(R, ctx.sample, ctx.example, algo, 'XY', ...
                                                        step, ctx.phase_index, ctx.phase_deg, CFG);
                rowsCell = [rowsCell, newRows]; %#ok<AGROW>
            catch ME
                fprintf(2, '    [fail] %s / generalized step_%d: %s\n', sampleLabel, step, ME.message);
            end
        end
        continue;
    end

    if strcmpi(algo, 'XY')
        % ЗВЕДЕНА карта: OX + OY (без усереднення). По кроках CFG.ortho.steps,
        % як generalized. OX/OY беруться з orthogonal-результату, якщо він на
        % диску; інакше рахуються в пам'яті з IMG (окремо НЕ зберігаються).
        for si = 1:numel(CFG.ortho.steps)
            step = CFG.ortho.steps(si);
            try
                R = tp_algo_XY(IMG, CFG, sampleOut, step);
                outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'XY', sprintf('step_%d', step));
                if ~exist(outDir,'dir'); mkdir(outDir); end
                save(fullfile(outDir,'result.mat'), 'R', '-v7.3');

                tp_visualize(R, CFG);
                newRows = tp_analytics_rows_for_result(R, ctx.sample, ctx.example, 'XY', 'XY', ...
                                                        step, ctx.phase_index, ctx.phase_deg, CFG);
                rowsCell = [rowsCell, newRows]; %#ok<AGROW>
            catch ME
                fprintf(2, '    [fail] %s / XY step_%d: %s\n', sampleLabel, step, ME.message);
            end
        end
        continue;
    end

    try
        t = tic;
        switch lower(algo)                   % крок 2: обчислення f_ik
            case 'orthogonal', R = tp_algo_orthogonal(IMG, CFG, sampleOut);
            case 'polar',      R = tp_algo_polar(IMG, CFG, sampleOut);
            otherwise
                warning('run_TwoPoint_Pipeline:algo', 'Невідомий алгоритм "%s" — пропущено.', algo);
                continue;
        end
        fprintf('    [%s] computed in %.1f s\n', algo, toc(t));

        % крок 3: зберегти — ОКРЕМИЙ result.mat у КОЖНІЙ підтеці напрям\крок
        % (orthogonal\OX\step_N\result.mat), так само як generalized уже
        % зберігає по кроках, а не один спільний файл на весь алгоритм.
        for di = 1:numel(R.dirs)
            dirName = R.dirs{di};
            sep = R.sep.(dirName);
            outDir = fullfile(CFG.paths.saveRoot, sampleOut, algo, sep.direction, sprintf('step_%d', sep.delta));
            if ~exist(outDir,'dir'); mkdir(outDir); end
            Rd = tp_slice_result_dir(R, dirName);
            save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');

            newRows = tp_analytics_rows_for_result(Rd, ctx.sample, ctx.example, algo, sep.direction, ...
                                                    sep.delta, ctx.phase_index, ctx.phase_deg, CFG);
            rowsCell = [rowsCell, newRows]; %#ok<AGROW>
        end

        tp_visualize(R, CFG);                % крок 4: візуалізація (з ПОВНОГО R — усі напрями разом)
    catch ME
        fprintf(2, '    [fail] %s / %s: %s\n', sampleLabel, algo, ME.message);
    end
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
function writePhaseInfo(fname, CFG, info)
% Короткий текстовий супровід фазового вікна — межі й частка збережених
% пікселів (для QC: чи не забагато NaN на вузьких вікнах).
fid = fopen(fname, 'w', 'n', 'UTF-8');
fprintf(fid, 'Фазова вибірка %d з %d\n', info.index, CFG.phase.numWindows);
fprintf(fid, 'Опорна фаза: delta_ref = angle(Ey) - angle(Ex), освітлення %s\n', CFG.phase.refPol);
fprintf(fid, 'Вікно: [%.6f, %.6f] рад  ([%.4f, %.4f] * pi)\n', ...
        info.lower, info.upper, info.lower/pi, info.upper/pi);
fprintf(fid, 'Збережено пікселів: %.2f%%\n', 100*info.keptFrac);
fclose(fid);
end
