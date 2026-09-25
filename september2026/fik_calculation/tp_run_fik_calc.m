function didRun = tp_run_fik_calc(CFG, sampleName, example, force)
% TP_RUN_FIK_CALC  Крок A для ОДНОГО зразка/прикладу: сирі комплексні Ex,Ey (.mat)
%   -> f_ik ('orthogonal' + 'XY') -> фазові вікна -> result.mat.
%
%   Це ЗВУЖЕНА адаптація august2026\run_TwoPoint_Pipeline.m: ті самі виклики
%   тих самих (байт-в-байт скопійованих у august2026_copy\) функцій, у тому самому
%   порядку, з тими самими шляхами й форматом збереження -- лише БЕЗ
%   візуалізації, аналітики, Горського та алгоритмів generalized/polar
%   (Крокові B вони не потрібні). Відповідність оригіналу:
%       tp_load_mat(CFG, sample, example)               <- рядок 87  (source='mat')
%       tp_algo_orthogonal(IMG, CFG, sampleOut)         <- рядок 209 (ОДИН раз на повному кадрі)
%       tp_phase_window_result(R, CFG, k)               <- рядки 270, 352
%       save orthogonal\<OX|OY>\step_<d>\result.mat, змінна Rd    <- рядки 276-279
%       tp_algo_XY([], CFG, phaseOut, step, ortho)      <- рядок 351 (XY з кешованого OX/OY)
%       save XY\step_<d>\result.mat, змінна R           <- рядки 356-358
%
%   Шляхи: сирі дані -- CFG.paths.matRoot; результат --
%       CFG.paths.saveRoot \ <зразок>\<приклад>\<фаза>\<алгоритм>\...\result.mat
%   (tp_prepare_fik_calc підставляє: реальні -- matRoot, модель -- simRoot; вихід -- fikRoot).
%   Фазові вікна: CFG.fik.phases (номери вікон або 'all'; див. tp_select_phases.m).
%
%   force (необов'язково, false): перерахувати, навіть якщо result.mat уже є.
%   didRun : true, якщо щось рахувалося; false -- усе вже було на диску.

if nargin < 4, force = false; end
tp_assert(isfield(CFG,'phase') && CFG.phase.enable, ...
    'tp_run_fik_calc: очікується CFG.phase.enable = true (як у пайплайні august2026)');

sampleOut = fullfile(sampleName, example);
U = tp_phase_window_bounds(CFG);
[phaseNames, ks] = tp_select_phases(CFG);      % які вікна обрано в CFG.fik.phases

% --- чи вже все пораховано? ---------------------------------------------
if ~force && allPresent(CFG, sampleOut, phaseNames)
    fprintf('  [fik_calc] %s: result.mat уже є, пропущено (force=false)\n', sampleOut);
    didRun = false;  return;
end

fprintf('  [fik_calc] %s: рахую orthogonal + XY ...\n', sampleOut);
IMG = tp_load_mat(CFG, sampleName, example);                 % готові комплексні Ex,Ey
t = tic;
ortho = tp_algo_orthogonal(IMG, CFG, sampleOut);              % повний кадр, без маски
fprintf('    [orthogonal] %.1f s\n', toc(t));

for k = ks
    phaseFolder = tp_phase_folder_name(CFG, k);
    phaseOut    = fullfile(sampleOut, phaseFolder);

    % ---- orthogonal: вікно -> по одному result.mat на напрям/крок (змінна Rd)
    R = tp_phase_window_result(ortho, CFG, k);
    for di = 1:numel(R.dirs)
        dirName = R.dirs{di};
        sep = R.sep.(dirName);
        outDir = fullfile(CFG.paths.saveRoot, phaseOut, 'orthogonal', sep.direction, sprintf('step_%d', sep.delta));
        if ~exist(outDir,'dir'); mkdir(outDir); end
        Rd = tp_slice_result_dir(R, dirName); %#ok<NASGU>
        save(fullfile(outDir,'result.mat'), 'Rd', '-v7.3');
    end

    % ---- XY: сума OX+OY з НЕМАСКОВАНОГО orthogonal у пам'яті, потім вікно
    for step = CFG.ortho.steps(:)'
        R = tp_algo_XY([], CFG, phaseOut, step, ortho);
        R = tp_phase_window_result(R, CFG, k); %#ok<NASGU>
        outDir = fullfile(CFG.paths.saveRoot, phaseOut, 'XY', sprintf('step_%d', step));
        if ~exist(outDir,'dir'); mkdir(outDir); end
        save(fullfile(outDir,'result.mat'), 'R', '-v7.3');
    end
    fprintf('    %s : per-element arg-вікно [0, %.3fpi] -> %s\n', phaseFolder, U(k)/pi, ...
            fullfile(CFG.paths.saveRoot, phaseOut));
end
didRun = true;
end

% ------------------------------------------------------------------------
function tf = allPresent(CFG, sampleOut, phaseNames)
tf = true;
for i = 1:numel(phaseNames)
    base = fullfile(CFG.paths.saveRoot, sampleOut, phaseNames{i});
    for step = CFG.ortho.steps(:)'
        tf = tf && isfile(fullfile(base, 'XY', sprintf('step_%d', step), 'result.mat')) ...
                && isfile(fullfile(base, 'orthogonal', 'OX', sprintf('step_%d', step), 'result.mat')) ...
                && isfile(fullfile(base, 'orthogonal', 'OY', sprintf('step_%d', step), 'result.mat'));
    end
end
end
