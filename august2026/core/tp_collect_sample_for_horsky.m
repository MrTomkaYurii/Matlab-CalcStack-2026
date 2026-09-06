function [nFilesOrtho, nFilesGen, nFilesPolar] = tp_collect_sample_for_horsky(CFG, sampleName)
% TP_COLLECT_SAMPLE_FOR_HORSKY  Збирає розкидані result.mat ОДНОГО зразка
%   в ОКРЕМИЙ файл на КОЖЕН приклад і алгоритм (не зливаючи приклади 1/2/3
%   в один файл) у CFG.paths.horskyRoot:
%       <Зразок>_<Приклад>_orthogonal.mat    (змінна всередині: orthogonal)
%       <Зразок>_<Приклад>_generalized.mat   (змінна всередині: generalized)
%       <Зразок>_<Приклад>_polar.mat         (змінна всередині: polar)
%   Читає лише те, що вже є на диску, нічого не рахує. Спільна логіка для:
%     - run_TwoPoint_Pipeline.m: викликається одразу як зразок дорахований
%       (Етап 3 ТЗ: "по мірі обчислення надсилати М. Горському"),
%     - run_TwoPoint_CollectForHorsky.m: окремий запуск на вимогу/повторно.
%
%   CFG.horsky.algorithms — який(і) алгоритм(и) збирати: підмножина
%   {'orthogonal','generalized','polar'} (за замовчуванням — усі три, якщо
%   поле не задане). Корисно, коли один алгоритм ще рахується, а інший уже
%   готовий і його треба віддати Горському, не чекаючи другого.
%
%   nFilesOrtho, nFilesGen, nFilesPolar : скільки файлів (на приклади)
%   реально записано для кожного алгоритму (0 => або зразок ще не
%   порахований, або цей алгоритм виключено через CFG.horsky.algorithms).

horskyRoot = CFG.paths.horskyRoot;
if ~exist(horskyRoot,'dir'); mkdir(horskyRoot); end

horskyAlgos = {'orthogonal','generalized','polar'};
if isfield(CFG,'horsky') && isfield(CFG.horsky,'algorithms') && ~isempty(CFG.horsky.algorithms)
    horskyAlgos = CFG.horsky.algorithms;
end
doOrtho = any(strcmpi(horskyAlgos,'orthogonal'));
doGen   = any(strcmpi(horskyAlgos,'generalized'));
doPolar = any(strcmpi(horskyAlgos,'polar'));

examplesList = {''};
if isfield(CFG.paths,'examples') && ~isempty(CFG.paths.examples)
    examplesList = CFG.paths.examples;
end

baseName = strrep(sampleName, ' ', '_');
nFilesOrtho = 0; nFilesGen = 0; nFilesPolar = 0;

phaseOn = isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable;
numK = 1; if phaseOn, numK = CFG.phase.numWindows; end

for ei = 1:numel(examplesList)
    example = examplesList{ei};
    if isempty(example)
        sampleOut = sampleName;
        fileBase  = baseName;
    else
        sampleOut = fullfile(sampleName, example);
        fileBase  = sprintf('%s_%s', baseName, example);
    end

    DataOrtho = struct(); DataGen = struct(); DataPolar = struct();
    nLoadedOrtho = 0; nLoadedGen = 0; nLoadedPolar = 0;

    for k = 1:numK
        if phaseOn
            phaseField = tp_phase_field_name(CFG, k);       % 'phase_0to360deg' - з інтервалом (град)
            phaseOut   = fullfile(sampleOut, tp_phase_folder_name(CFG, k));
        else
            phaseField = '';
            phaseOut   = sampleOut;
        end

        % orthogonal: ОКРЕМИЙ result.mat у кожній підтеці <OX|OY>\step_N\ ->
        % ключ у зведеній структурі ОБОВ'ЯЗКОВО включає крок (OX_step_1,
        % OX_step_2, ...), інакше різні кроки одного напряму переписують
        % один одного (був баг: виживав лише останній прочитаний крок).
        if doOrtho
            orthoPacked = struct();
            for dirLabel = {'OX','OY'}
                dirRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'orthogonal', dirLabel{1});
                if ~isfolder(dirRoot), continue; end
                stepDirs = dir(fullfile(dirRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(dirRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    S = load(rFile, 'Rd');
                    key = sprintf('%s_%s', dirLabel{1}, stepDirs(si).name);   % напр. OX_step_1
                    orthoPacked.(key) = packElements(S.Rd);
                    nLoadedOrtho = nLoadedOrtho + 1;
                end
            end
            if ~isempty(fieldnames(orthoPacked))
                DataOrtho = putField(DataOrtho, phaseField, orthoPacked);
            end
        end

        % generalized: окремий result.mat на кожен крок (підтека step_N) ->
        % ключ = step_N (крок сам по собі унікальний, напрям тут один XY).
        if doGen
            genRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'generalized');
            if isfolder(genRoot)
                stepDirs = dir(fullfile(genRoot, 'step_*'));
                genPacked = struct();
                for si = 1:numel(stepDirs)
                    genFile = fullfile(genRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(genFile), continue; end
                    S = load(genFile, 'R');
                    genPacked.(stepDirs(si).name) = packElements(S.R);
                    nLoadedGen = nLoadedGen + 1;
                end
                if ~isempty(fieldnames(genPacked))
                    DataGen = putField(DataGen, phaseField, genPacked);
                end
            end
        end

        % polar: окремий result.mat у теках PERP\ , OX\ , OY\ (крок = радіус
        % rho). PERP_step_<d> — ЄДИНА карта: КОМПЛЕКСНА СУМА Sum_theta f по
        % всіх напрямах (БЕЗ ділення). OX/OY_step_<d> — осьові зрізи theta=0
        % / 90 (для оцінки орієнтаційної анізотропії). Ключ включає крок —
        % так само як для orthogonal.
        if doPolar
            polarPacked = struct();
            for dirLabel = {'PERP','OX','OY'}
                dirRoot = fullfile(CFG.paths.saveRoot, phaseOut, 'polar', dirLabel{1});
                if ~isfolder(dirRoot), continue; end
                stepDirs = dir(fullfile(dirRoot, 'step_*'));
                for si = 1:numel(stepDirs)
                    rFile = fullfile(dirRoot, stepDirs(si).name, 'result.mat');
                    if ~isfile(rFile), continue; end
                    S = load(rFile, 'Rd');
                    key = sprintf('%s_%s', dirLabel{1}, stepDirs(si).name);   % напр. PERP_step_1
                    polarPacked.(key) = packElements(S.Rd);
                    % ЄДИНА карта: скільки напрямів реально ввійшло в Sum_theta на
                    % піксель (край кадру < nAngles) — для нормування на боці Горського.
                    if strcmp(dirLabel{1}, 'PERP') && isfield(S.Rd,'params') ...
                            && isfield(S.Rd.params,'validCount')
                        vcName = S.Rd.dirs{1};                       % 'PERP_step_<rho>'
                        if isfield(S.Rd.params.validCount, vcName)
                            polarPacked.(key).validCount = S.Rd.params.validCount.(vcName);
                        end
                    end
                    nLoadedPolar = nLoadedPolar + 1;
                end
            end
            if ~isempty(fieldnames(polarPacked))
                DataPolar = putField(DataPolar, phaseField, polarPacked);
            end
        end
    end

    if nLoadedOrtho > 0
        orthogonal = DataOrtho;
        save(fullfile(horskyRoot, [fileBase '_orthogonal.mat']), 'orthogonal', '-v7.3');
        nFilesOrtho = nFilesOrtho + 1;
    end
    if nLoadedGen > 0
        generalized = DataGen;
        save(fullfile(horskyRoot, [fileBase '_generalized.mat']), 'generalized', '-v7.3');
        nFilesGen = nFilesGen + 1;
    end
    if nLoadedPolar > 0
        polar = DataPolar;
        save(fullfile(horskyRoot, [fileBase '_polar.mat']), 'polar', '-v7.3');
        nFilesPolar = nFilesPolar + 1;
    end
end
end

% ------------------------------------------------------------------------
function DATA = putField(DATA, phaseField, value)
if isempty(phaseField)
    % без фазових вибірок (CFG.phase.enable=false) -> кладемо напряму,
    % без проміжного рівня
    fn = fieldnames(value);
    for f = 1:numel(fn)
        DATA.(fn{f}) = value.(fn{f});
    end
else
    DATA.(phaseField) = value;
end
end

% ------------------------------------------------------------------------
function P = packElements(R)
% R завжди містить РІВНО один напрям (Rd зі зрізу tp_slice_result_dir для
% orthogonal, або єдиний "XY" для generalized) — тому напрям тут НЕ
% потрібен у структурі: ключ напрям+крок вже задається в місці виклику.
P = struct();
dirName = R.dirs{1};
els = fieldnames(R.data.(dirName));
for e = 1:numel(els)
    entry = R.data.(dirName).(els{e});
    P.(els{e}) = struct('mod', entry.mod, 'arg', entry.arg);
end
end
