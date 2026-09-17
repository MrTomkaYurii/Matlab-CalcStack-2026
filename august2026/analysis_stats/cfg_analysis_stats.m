function CFG = cfg_analysis_stats()
% CFG_ANALYSIS_STATS  Конфігурація модуля швидкої аналітики stats-таблиць.
%   Читає порахованих stats.*.txt з paper_figures (Fig1–Fig7) і будує
%   оглядові PNG-рисунки для контролю статистичних моментів.

CFG = struct();

% ─── Джерело даних (де лежать FigN/stats.*.txt) ───────────────────────
CFG.dataRoot = 'C:\August 2026-Results\Розрахунки - Скомпановані рисунки';

% ─── Вивід (PNG, кеш) ────────────────────────────────────────────────
CFG.outRoot = 'C:\August 2026-Results\Аналітика - Статистичні моменти';

% ─── Зразки (англ. теги як у txt-файлах, укр. підписи для графіків) ───
CFG.samples     = {'heart', 'muscle', 'brain'};
CFG.sampleNames = {'Heart', 'Muscle', 'Brain'};   % для легенд/осей

% ─── DPI растрових PNG ───────────────────────────────────────────────
CFG.dpi = 200;

% ─── Примусовий перепарсинг (ігнорувати кешований all_stats.mat) ──────
CFG.forceReparse = false;

% ─── Що будувати (підмножина або все) ────────────────────────────────
%   'by_samples'    — порівняння зразків (тканин)
%   'by_algorithms' — порівняння алгоритмів (XY/gen/OX/OY)
%   'by_phase'      — ефект звуження фазового вікна
%   'heatmaps'      — зведені heatmap-dashboards
CFG.build = {'by_samples', 'by_algorithms', 'by_phase', 'heatmaps'};

end
