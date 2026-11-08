function run_Recolor_Arg(firstStage, onlyFiles)
% RUN_RECOLOR_ARG  Перемальовує ВСІ рисунки з картами аргументу у палітрі CET-C6
%   (замість hsv) у ОКРЕМУ теку C:\August 2026-Results-2 з тією самою
%   структурою й іменами файлів, що в C:\August 2026-Results. Нічого не
%   рахує: лише читає готові result.mat.
%
%   Етап A — поелементні рисунки (з result.mat, ~5-7 год):
%       00_overview_*, fXX_maps_hist, _block1_, fXX_surf_contour, fXX_contour3d,
%       _block3_, fXX_level_bands_*  (усе, де є карта arg).
%       НЕ перемальовуються (arg там не фаза, палітра jet лишається): вейвлет,
%       АКФ/PSD, перерізи АКФ, скелетон, мультифрактал, fXX_stats.txt.
%   Етап B — скомпоновані рисунки Fig1 і Fig7 (лише в них карти arg; ~1 год).
%       Fig2-Fig6 показують АКФ / PSD / вейвлет arg — палітра jet, не чіпаємо.
%
%   Відновлення після вимкнення світла: просто запустити ще раз.
%     етап A — тека з viz_c6_done.txt у Results-2 пропускається;
%     етап B — fig_exists пропускає вже збережені рисунки;
%     журнал етапів: C:\August 2026-Results-2\recolor_journal.txt.
%   run_Recolor_Arg(2) — одразу етап B.
%   run_Recolor_Arg(1, {'...\result.mat', ...}) — тест: лише ці файли етапу A,
%       журнал етапів не чіпається.
%
%   Після завершення — див. README.md (копіювання поверх основної теки).

if nargin < 1, firstStage = 1; end
if nargin < 2, onlyFiles = {}; end
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(repo, fullfile(repo,'config'), genpath(fullfile(repo,'core')), fullfile(repo,'io'), ...
        fullfile(repo,'viz'), fullfile(repo,'simulation'), fullfile(repo,'analysis_ММ'), ...
        fullfile(repo,'paper_figures'), fullfile(repo,'paper_figures','common'));
if exist('cet_c6', 'file') ~= 2
    error('run_Recolor_Arg:cmap', ['Немає core\\cet_c6.m — спершу: python "%s"'], ...
          fullfile(here, 'make_cet_c6_table.py'));
end

SRC  = 'C:\August 2026-Results';
DST  = 'C:\August 2026-Results-2';
if ~exist(DST, 'dir'); mkdir(DST); end
oldVis = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');
restoreVis = onCleanup(@() set(groot, 'DefaultFigureVisible', oldVis));
logFile = fullfile(DST, ['recolor_' char(datetime('now','Format','yyyyMMdd_HHmm')) '.log']);
diary(logFile);  diaryOff = onCleanup(@() diary('off'));
journal = fullfile(DST, 'recolor_journal.txt');

if ~isempty(onlyFiles)                       % тестовий режим
    stageA(SRC, DST, onlyFiles);
    fprintf('\n=== Тест готовий: %s ===\n', DST);
    return;
end

stages = {
    'A. Поелементні рисунки (arg -> CET-C6)', @() stageA(SRC, DST)
    'B. Скомпоновані Fig1, Fig7 (arg -> CET-C6)', @() stageB(SRC, DST)
    };
for i = firstStage:size(stages, 1)
    if isDone(journal, stages{i,1})
        fprintf('#### %s — вже виконано (журнал), пропускаю ####\n', stages{i,1});
        continue;
    end
    fprintf('\n#### %s  [%s] ####\n', stages{i,1}, char(datetime('now','Format','HH:mm')));
    note(journal, 'START', stages{i,1});
    try
        stages{i,2}();
        note(journal, 'DONE', stages{i,1});
    catch ME
        note(journal, 'FAIL', [stages{i,1} ' : ' ME.message]);
        fprintf(2, '[fail] %s\n', getReport(ME));
    end
end
fprintf('\n=== Готово. Результат: %s (лог %s) ===\n', DST, logFile);
end

% ------------------------------------------------------------------------
function stageA(SRC, DST, onlyFiles)
if nargin < 3, onlyFiles = {}; end
CFG = cfg_TwoPoint();
srcRoot = CFG.paths.saveRoot;                                  % ...\Розрахунки - Двот. елем. ММ
CFG.paths.saveRoot = strrep(srcRoot, SRC, DST);               % той самий шлях під Results-2
% лише подання з картою arg
off = {'multifractal','wavelet','acfPsd','acfCuts','skeleton','statsTable'};
for k = 1:numel(off); CFG.viz.(off{k}) = false; end

L = dir(fullfile(srcRoot, '**', 'result.mat'));
files = fullfile({L.folder}, {L.name});
if ~isempty(onlyFiles); files = cellstr(onlyFiles); end
fprintf('result.mat: %d;  вивід: %s\n', numel(files), CFG.paths.saveRoot);
nOk = 0; nFail = 0; nSkip = 0; t0 = tic;
for i = 1:numel(files)
    f = files{i};
    dstDir = strrep(fileparts(f), srcRoot, CFG.paths.saveRoot);
    doneFile = fullfile(dstDir, 'viz_c6_done.txt');
    if isfile(doneFile); nSkip = nSkip + 1; continue; end
    fprintf('\n[%d/%d] %s\n', i, numel(files), f);
    try
        S = load(f);
        if isfield(S,'R'); R = S.R; else; R = S.Rd; end
        R = sampleFromPath(R, f, srcRoot);
        t = tic;
        tp_visualize(R, CFG);
        if ~exist(dstDir,'dir'); mkdir(dstDir); end
        fid = fopen(doneFile, 'w', 'n', 'UTF-8');
        fprintf(fid, '%s\n', char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'))); fclose(fid);
        fprintf('  [ok] %.1f s\n', toc(t));
        nOk = nOk + 1;
    catch ME
        fprintf(2, '  [fail] %s\n', ME.message);
        nFail = nFail + 1;
    end
    tp_progress(nOk + nFail, numel(files) - nSkip, t0, sprintf('рисунки %d/%d', i, numel(files)));
end
fprintf('\n=== Етап A: %d ок, %d з помилками, %d пропущено ===\n', nOk, nFail, nSkip);
if nFail > 0
    error('run_Recolor_Arg:stageA', '%d result.mat з помилками (див. лог)', nFail);
end
end

function stageB(SRC, DST)
FIG = cfg_figures();
FIG.out.root  = strrep(FIG.out.root, SRC, DST);
FIG.build     = {'Fig1','Fig7'};               % таблиці моментів не змінюються
FIG.color.maps.color.arg = 'cet_c6';
run_all_figures(FIG);
end

% ------------------------------------------------------------------------
function R = sampleFromPath(R, matFile, root)
% R.sample = усе між root і текою алгоритму (як у run_TwoPoint_VizFromResults)
rel = regexprep(erase(fileparts(matFile), root), '^[\\/]+', '');
parts = regexp(rel, '[\\/]+', 'split');
ai = find(strcmpi(parts,'generalized') | strcmpi(parts,'orthogonal'), 1);
if ~isempty(ai) && ai > 1
    R.sample = strjoin(parts(1:ai-1), filesep);
end
end

function note(journal, tag, msg)
fid = fopen(journal, 'a', 'n', 'UTF-8');
fprintf(fid, '%s | %s | %s\n', tag, msg, char(datetime('now','Format','yyyy-MM-dd HH:mm')));
fclose(fid);
end

function tf = isDone(journal, stage)
tf = false;
if ~isfile(journal); return; end
L = splitlines(fileread(journal));
tf = any(startsWith(L, ['DONE | ' stage ' |']));
end
