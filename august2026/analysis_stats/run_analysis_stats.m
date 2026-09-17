function run_analysis_stats(cfgOverride)
% RUN_ANALYSIS_STATS  Швидка аналітика статистичних моментів Fig1–Fig7.
%   Єдина точка входу: парсить усі stats.*.txt, будує 4 типи оглядових
%   PNG-рисунків, зберігає в analysis_stats/output/.
%
%   Використання:
%       run_analysis_stats                   % бере cfg_analysis_stats()
%       run_analysis_stats(myCFG)            % власна конфігурація
%
%   Що будує (налаштовується в CFG.build):
%     'by_samples'    — порівняння зразків (тканин): grouped bars
%     'by_algorithms' — порівняння алгоритмів: grouped bars
%     'by_phase'      — фазовий ефект: scatter (x = широке, y = вузьке)
%     'heatmaps'      — зведені heatmap-dashboards
%
%   Чисто читає готові текстові таблиці — НІЧОГО не рахує заново.

here = fileparts(mfilename('fullpath'));
addpath(here);

if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_analysis_stats();
end

fprintf('============================================================\n');
fprintf('  Аналітика stats-таблиць Fig1–Fig7\n');
fprintf('============================================================\n');
fprintf('Джерело : %s\n', CFG.dataRoot);
fprintf('Вивід   : %s\n', CFG.outRoot);
fprintf('Будую   : %s\n\n', strjoin(CFG.build, ', '));

%% ─── 1. Збір даних ────────────────────────────────────────────────────
t0 = tic;
T = collect_all_stats(CFG);

if isempty(T) || height(T) == 0
    fprintf(2, 'Таблиця порожня — нема що аналізувати.\n');
    return;
end
fprintf('Зібрано %d рядків за %.1f с\n\n', height(T), toc(t0));

% Коротке зведення
fprintf('  statsTypes : %s\n', strjoin(unique(T.statsType)', ', '));
fprintf('  algos      : %s\n', strjoin(unique(T.algo)', ', '));
fprintf('  samples    : %s\n', strjoin(unique(T.sample)', ', '));
fprintf('  elements   : %d унікальних\n', numel(unique(T.element)));
fprintf('  phases     : %s\n\n', strjoin(compose('%.2g', unique(T.phaseWidth)'), ', '));

build = CFG.build;

%% ─── 2. Зріз 1: по зразках ───────────────────────────────────────────
if any(strcmpi(build, 'by_samples'))
    fprintf('--- Зріз 1: порівняння зразків ---\n');
    t1 = tic;
    plot_by_samples(T, CFG);
    fprintf('  Готово за %.1f с\n\n', toc(t1));
end

%% ─── 3. Зріз 2: по алгоритмах ────────────────────────────────────────
if any(strcmpi(build, 'by_algorithms'))
    fprintf('--- Зріз 2: порівняння алгоритмів ---\n');
    t2 = tic;
    plot_by_algorithms(T, CFG);
    fprintf('  Готово за %.1f с\n\n', toc(t2));
end

%% ─── 4. Зріз 3: фазовий ефект ────────────────────────────────────────
if any(strcmpi(build, 'by_phase'))
    fprintf('--- Зріз 3: фазовий ефект ---\n');
    t3 = tic;
    plot_by_phase(T, CFG);
    fprintf('  Готово за %.1f с\n\n', toc(t3));
end

%% ─── 5. Зведені heatmaps ─────────────────────────────────────────────
if any(strcmpi(build, 'heatmaps'))
    fprintf('--- Зведені heatmaps ---\n');
    t4 = tic;
    plot_heatmap_summary(T, CFG);
    fprintf('  Готово за %.1f с\n\n', toc(t4));
end

%% ─── 6. Генерація Word-гайду (.docx) ──────────────────────────────────
try
    make_analytics_guide_docx();
catch ME
    fprintf(2, '[Попередження] Не вдалось згенерувати .docx гайд: %s\n', ME.message);
end

%% ─── Підсумок ─────────────────────────────────────────────────────────
fprintf('============================================================\n');
fprintf('  Готово за %.0f с. Результати: %s\n', toc(t0), CFG.outRoot);
fprintf('============================================================\n');

end
