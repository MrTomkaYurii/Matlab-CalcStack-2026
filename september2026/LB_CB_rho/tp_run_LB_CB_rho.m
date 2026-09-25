function tp_run_LB_CB_rho(CFG)
% TP_RUN_LB_CB_RHO  Прогін Кроку B за налаштуваннями CFG (cfg_September.m):
%   для кожного  зразок × приклад × фазове вікно × алгоритм × крок  --
%       result.mat Кроку A  ->  LB_0_90, LB_45_135, CB, rho, LB  ->
%       збереження чисел (CFG.stepB.saveMat)  ->  статистика (CFG.stepB.stats:
%       <елемент>_stats.txt у теці кожного елемента)  ->  рисунки (CFG.stepB.visualize,
%       лише для вікон CFG.viz.phases)  ->  наприкінці аналітика (CFG.stepB.analytics).
%   Жодних хардкодів: усе, що змінюється між прогонами, лежить у CFG.
%   Крок A (f_ik) рахується з нуля з сирих полів (CFG.fik.source = 'compute') або береться
%   з готових August-результатів ('august'); у 'orthogonal' змінна result.mat зветься Rd, в інших -- R.
%   Фазові вікна -- CFG.fik.phases (номери або 'all'), рисунки -- CFG.viz.phases.

% Крок A (f_ik) з нуля з сирих полів: для реальних зразків (CFG.fik.source = 'compute') і
% для моделі. Сирі поля МОДЕЛІ тут не створюються -- їх раз створює run_sim_model.m; якщо їх
% ще нема, буде [fik_calc skip] з підказкою. Що вже є на диску -- не перераховується
% (CFG.fik.recompute = false).
tp_prepare_fik_calc(CFG);

[phaseNames, phaseIdx] = tp_select_phases(CFG);              % для яких вікон рахуємо
[~, vizPhaseIdx]       = tp_select_phases(CFG, CFG.viz.phases);   % для яких -- ще й рисунки

nDone = 0;  nSkipped = 0;  allRows = {};
for s = 1:numel(CFG.samples)
    for e = 1:numel(CFG.paths.examples)
        smp = CFG.samples{s};  ex = CFG.paths.examples{e};

        if isBroken(CFG, smp, ex)
            fprintf('[skip] %s\\%s: відомо биті вхідні канали (CFG.dataHealth.broken)\n', smp, ex);
            nSkipped = nSkipped + 1;  continue;
        end
        base = fullfile(fikRootFor(CFG, smp), smp, ex);
        if ~isfolder(base)
            fprintf(2, '[skip] %s\\%s: немає теки %s%s\n', smp, ex, base, simHint(CFG, smp));
            nSkipped = nSkipped + 1;  continue;
        end

        for p = 1:numel(phaseNames)
            phase = phaseNames{p};  k = phaseIdx(p);
            for a = 1:numel(CFG.algorithms)
                alg = CFG.algorithms{a};
                algDir = fullfile(base, phase, alg);
                files = dir(fullfile(algDir, '**', 'result.mat'));
                if isempty(files)
                    fprintf(2, '[skip] %s\\%s\\%s\\%s: немає result.mat%s\n', smp, ex, phase, alg, simHint(CFG, smp));
                    nSkipped = nSkipped + 1;  continue;
                end
                [~, order] = sort(fullfile({files.folder}, {files.name}));   % OX перед OY -- стабільний порядок
                for f = order(:)'
                    file = fullfile(files(f).folder, files(f).name);
                    R = loadResult(file);
                    % ОДНАКОВА схема шляху для всіх алгоритмів: зразок\приклад\фаза
                    % (у 'orthogonal' R.sample містить лише зразок\приклад -- без
                    % фази різні фазові вікна писали б в одну теку; у August-файлі
                    % phase_03 XY поле R.sample також містить назву phase_01).
                    R.sample = strjoin({smp, ex, phase}, '\');
                    for d = 1:numel(R.dirs)
                        dName = R.dirs{d};
                        if ~stepWanted(dName, CFG.fik.steps), continue; end
                        rows = runOne(R, dName, CFG, k, ismember(k, vizPhaseIdx));
                        allRows = [allRows, rows]; %#ok<AGROW>
                        nDone = nDone + 1;
                    end
                end
            end
        end
    end
end
fprintf('\nГотово: оброблено %d напрямів/кроків, пропущено %d. Вихід: %s\n', ...
        nDone, nSkipped, CFG.paths.saveRoot);

% ---- аналітика: рядки таблиці (накопичені вище) -> таблиця по алгоритмах -> тренди/рисунки
if CFG.stepB.analytics && ~isempty(allRows)
    tp_an_append_rows(CFG, allRows);
    tp_run_analytics(CFG);
end
end

% ------------------------------------------------------------------------
function rows = runOne(R, dName, CFG, k, doViz)
fprintf('\n=== %s | %s | %s ===\n', R.sample, R.algorithm, dName);
R2 = tp_LB_CB_rho_from_result(R, dName);

for e = 1:numel(R2.elements)
    elem = R2.elements{e};
    D = R2.data.(dName).(elem);
    v = D.mod(isfinite(D.mod));  a = D.arg(isfinite(D.arg));
    fprintf('  %-10s |.| mean=%10.4g std=%10.4g   arg mean=%7.4f std=%7.4f  (n=%d/%d finite)\n', ...
        elem, mean(v), std(v), mean(a), std(a), numel(v), numel(D.mod));
end

if CFG.stepB.saveMat
    fprintf('  числа -> %s\n', tp_save_LB_CB_rho_result(R2, dName, CFG));
end

% статистика: текстові файли (stepB.stats) і/або рядки для аналітики (stepB.analytics)
rows = {};
if CFG.stepB.stats || CFG.stepB.analytics
    rows = tp_stats_LB_CB_rho(R2, dName, CFG, k, CFG.stepB.stats);
    if CFG.stepB.stats, fprintf('  статистика -> <елемент>\\<елемент>_stats.txt (5 файлів)\n'); end
end

if CFG.stepB.visualize && doViz
    tp_visualize_LB_CB_rho(R2, dName, CFG);
end
end

% ------------------------------------------------------------------------
function s = simHint(CFG, smp)
% Для модельного зразка -- підказка, що його готує окремий скрипт.
s = '';
if any(strcmp(CFG.simSamples, smp))
    s = '  (перевір, що модель створено -- run_sim_model.m)';
end
end

% ------------------------------------------------------------------------
function root = fikRootFor(CFG, smp)
% Де лежать result.mat Кроку A: те, що порахував наш fik_calculation\tp_run_fik_calc.m (fikRoot) --
% для модельних завжди, для реальних при CFG.fik.source='compute'; при 'august' реальні
% беруться з готових August-результатів (CFG.paths.fikAugustRoot).
if strcmpi(CFG.fik.source, 'compute') || any(strcmp(CFG.simSamples, smp))
    root = CFG.paths.fikRoot;
else
    root = CFG.paths.fikAugustRoot;
end
end

% ------------------------------------------------------------------------
function R = loadResult(file)
% Змінна у result.mat: 'R' (XY, generalized, ...) або 'Rd' (orthogonal).
S = load(file);
if isfield(S, 'R')
    R = S.R;
elseif isfield(S, 'Rd')
    R = S.Rd;
else
    error('tp_run_LB_CB_rho: %s не містить змінної R чи Rd (є: %s)', file, strjoin(fieldnames(S)', ','));
end
end

% ------------------------------------------------------------------------
function tf = isBroken(CFG, smp, ex)
tf = false;
if isfield(CFG,'dataHealth') && isfield(CFG.dataHealth,'broken')
    if isfield(CFG.dataHealth,'runBroken') && CFG.dataHealth.runBroken, return; end
    tf = any(strcmp(CFG.dataHealth.broken, [smp '\' ex]));
end
end

% ------------------------------------------------------------------------
function tf = stepWanted(dName, steps)
% dName закінчується на 'step_<d>' (step_1, OX_step_1, ...); d має бути в steps.
tf = false;
for d = steps(:)'
    if endsWith(dName, sprintf('step_%d', d)), tf = true; return; end
end
end
