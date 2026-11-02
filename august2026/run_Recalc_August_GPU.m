function run_Recalc_August_GPU(onlyCheck)
% RUN_RECALC_AUGUST_GPU  Повний перерахунок серпневих result.mat на GPU (RTX 5070).
%   run_Recalc_August_GPU          % перевірка GPU + звірка з CPU + повний розрахунок
%   run_Recalc_August_GPU(true)    % лише перевірка GPU і звірка з CPU
%
%   Що рахується: усі зразки CFG.samples x приклади CFG.paths.examples x
%   усі фазові вікна (маска на ПОЛІ, кожне освітлення за своєю phi_xy) x
%   алгоритми CFG.algorithms ('orthogonal','XY','generalized').
%   generalized — пачками на GPU (tp_algo_generalized_batch.m, single,
%   суми в double). Шляхи — у config/cfg_TwoPoint.m (C:\August 2026-Results\...):
%   вхідні .mat мають лежати в CFG.paths.matRoot.

if nargin < 1, onlyCheck = false; end
here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'config'), genpath(fullfile(here,'core')));

% ---- 1. GPU
% RTX 50xx (Blackwell) може бути новішою за CUDA, з якою зібраний MATLAB —
% тоді потрібен режим сумісності (одноразова JIT-компіляція, перший запуск довший).
try
    parallel.gpu.enableCUDAForwardCompatibility(true);
catch
end
assert(canUseGPU(), ['MATLAB не бачить GPU NVIDIA. Потрібні Parallel Computing Toolbox ' ...
                     'і драйвер NVIDIA; перевірка: gpuDevice']);
dev = gpuDevice;
fprintf('GPU: %s, %.1f ГБ, compute capability %s\n', dev.Name, dev.TotalMemory/2^30, dev.ComputeCapability);

% ---- 2. Звірка GPU з CPU на малому кадрі (60x60, Серце/1, вікна 1 і 4)
CFG = cfg_TwoPoint();
C0 = CFG;  C0.crop.size = 60;
IMG0 = tp_load_mat(C0, CFG.samples{1}, CFG.paths.examples{1});
for k = [1 4]
    if k == 1, IMG = IMG0; else, IMG = tp_phase_window(IMG0, C0, k); end
    Cc = C0; Cc.gen.useGPU = false; Cc.gen.precision = 'double';
    Cg = C0; Cg.gen.useGPU = true;  Cg.gen.precision = 'single';
    Rc = tp_algo_generalized_batch(IMG, Cc, 'check', 1);
    t = tic; Rg = tp_algo_generalized_batch(IMG, Cg, 'check', 1); tg = toc(t);
    worst = 0;
    for e = 1:numel(CFG.elements)
        A = Rc.data.step_1.(CFG.elements{e});  B = Rg.data.step_1.(CFG.elements{e});
        m = isfinite(A.mod) & isfinite(B.mod);
        assert(isequal(isfinite(A.mod), isfinite(B.mod)), 'GPU/CPU: різні NaN-маски (%s)', CFG.elements{e});
        worst = max([worst; abs(A.mod(m)-B.mod(m)) ./ max(abs(A.mod(m)), eps)]);   % пустий елемент (немає каналу) не ламає звірку
    end
    fprintf('звірка, вікно %d: макс. відн. різниця |f| GPU vs CPU = %.2e (GPU %.2f c)\n', k, worst, tg);
    assert(worst < 1e-3, 'GPU і CPU розходяться більше ніж на 1e-3 — розрахунок зупинено');
end
if onlyCheck, return; end

% ---- 3. Повний розрахунок
CFG.gen.engine    = 'batch';
CFG.gen.useGPU    = true;
CFG.gen.precision = 'single';
CFG.gen.batchShifts = 128;
t = tic;
run_TwoPoint_Pipeline(CFG);
fprintf('\n=== Перерахунок завершено за %.1f год ===\n', toc(t)/3600);
end
