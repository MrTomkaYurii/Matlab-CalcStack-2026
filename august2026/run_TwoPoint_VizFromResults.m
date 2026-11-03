function run_TwoPoint_VizFromResults(target, cfgOverride)
% RUN_TWOPOINT_VIZFROMRESULTS  Домальовує візуалізації з УЖЕ порахованих
%   result.mat — нічого не рахує заново. Для випадку "розрахунок завершився,
%   а картинки не встигли вивестись" (обірвали прогін, впав parfor на viz,
%   мінявся CFG.viz.* після розрахунку тощо).
%
%   Кожен result.mat самодостатній: усередині лежить канонічна структура
%   (R для generalized, Rd для orthogonal) з власним R.sample / R.algorithm /
%   R.elements / R.axes — тому tp_visualize кладе рисунки рівно туди, звідки
%   взято result.mat, незалежно від поточного CFG (з CFG беруться лише
%   CFG.viz.* перемикачі, стиль і CFG.out.*).
%
%   R.sample додатково звіряється зіШЛЯХОМ result.mat і за потреби
%   виправляється (напр. якщо файл колись зберіг run_TwoPoint_FillMissing,
%   що клав у R.sample шлях без фазової підтеки) — щоб рисунки не розʼїхались.
%
%   Не змінює result.mat, аналітику, збірку для Горського. Перемальовує
%   (перезаписує) усі увімкнені подання для знайдених result.mat — часткові
%   картинки з обірваного прогону замінюються повним набором.
%
%   Використання:
%       run_TwoPoint_VizFromResults
%           % усі result.mat під CFG.paths.saveRoot
%       run_TwoPoint_VizFromResults('C:\...\phase_08_[0-0.25pi]\generalized\step_1')
%           % одна тека (рекурсивно) або конкретний ...\result.mat
%       run_TwoPoint_VizFromResults(target, myCFG)
%           % власна структура CFG (напр. звузити CFG.viz.* до того, чого бракує)

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), genpath(fullfile(here,'core')), ...
        fullfile(here,'io'),     fullfile(here,'viz'), fullfile(here,'simulation'), ...
        fullfile(here,'analysis_ММ'));

if nargin >= 2 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end
tp_check_config(CFG);

if nargin < 1 || isempty(target)
    target = CFG.paths.saveRoot;
end

% ---- зібрати список result.mat -------------------------------------------
if isfile(target)
    files = {target};
elseif isfolder(target)
    L = dir(fullfile(target, '**', 'result.mat'));
    files = fullfile({L.folder}, {L.name});
else
    error('run_TwoPoint_VizFromResults:target', 'Не знайдено (ні файл, ні тека): %s', target);
end
if isempty(files)
    fprintf('result.mat не знайдено під: %s\n', target);
    return;
end

fprintf('=== Візуалізація з готових result.mat: %d файл(ів) ===\n', numel(files));
% Журнал: після успішного малювання поряд із result.mat кладеться viz_done.txt.
% Після перерви (вимкнули світло) такі теки пропускаються — продовжуємо з місця
% зупинки. Перемалювати все заново: видалити viz_done.txt (або CFG.viz.redo = true).
redo = isfield(CFG.viz,'redo') && CFG.viz.redo;
nOk = 0; nFail = 0; nSkip = 0; tAll = tic;
for i = 1:numel(files)
    f = files{i};
    doneFile = fullfile(fileparts(f), 'viz_done.txt');
    if ~redo && isfile(doneFile)
        nSkip = nSkip + 1;
        continue;
    end
    fprintf('\n[%d/%d] %s\n', i, numel(files), f);
    try
        S = load(f);
    catch ME
        fprintf(2, '  [skip] не вдалось завантажити: %s\n', ME.message);
        nFail = nFail + 1; continue;
    end

    if isfield(S, 'R'),        R = S.R;
    elseif isfield(S, 'Rd'),   R = S.Rd;
    else
        fprintf(2, '  [skip] у файлі немає ні R, ні Rd\n');
        nFail = nFail + 1; continue;
    end

    R = fixSampleFromPath(R, f, CFG);

    try
        t = tic;
        tp_visualize(R, CFG);
        fprintf('  [ok] %s | %s | %s : намальовано за %.1f s\n', ...
                R.sample, R.algorithm, strjoin(R.dirs, ','), toc(t));
        nOk = nOk + 1;
        fid = fopen(doneFile, 'w', 'n', 'UTF-8');
        fprintf(fid, '%s\n', char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
        fclose(fid);
    catch ME
        fprintf(2, '  [fail] tp_visualize: %s\n', ME.message);
        nFail = nFail + 1;
    end
    tp_progress(nOk + nFail, numel(files) - nSkip, tAll, sprintf('рисунки %d/%d', i, numel(files)));
end

fprintf('\n=== Готово: %d ок, %d з помилками, %d пропущено (вже намальовані) ===\n', nOk, nFail, nSkip);
end

% ------------------------------------------------------------------------
function R = fixSampleFromPath(R, matFile, CFG)
% Відновлює R.sample зі шляху result.mat відносно CFG.paths.saveRoot:
%   saveRoot \ <sample...> \ <algorithm> \ [<DIR> \] step_N \ result.mat
% Усе до теки алгоритму ('generalized'/'orthogonal') — це R.sample.
folder = fileparts(matFile);
root   = CFG.paths.saveRoot;
rel = erase(folder, root);
rel = regexprep(rel, '^[\\/]+', '');
parts = regexp(rel, '[\\/]+', 'split');
parts = parts(~cellfun(@isempty, parts));

ai = find(strcmpi(parts, 'generalized') | strcmpi(parts, 'orthogonal'), 1, 'first');
if isempty(ai) || ai == 1
    return;   % нестандартний шлях — не чіпаємо, лишаємо R.sample як є
end
sampleFromPath = strjoin(parts(1:ai-1), filesep);

if ~strcmp(R.sample, sampleFromPath)
    fprintf(2, '  [note] R.sample = "%s" -> виправлено на "%s" (за шляхом файлу)\n', ...
            R.sample, sampleFromPath);
    R.sample = sampleFromPath;
end
end
