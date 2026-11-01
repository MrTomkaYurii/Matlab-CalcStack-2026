function R = tp_algo_generalized_run(IMG, CFG, sampleName, step)
% TP_ALGO_GENERALIZED_RUN  Вибір реалізації узагальненого скану за CFG.gen.engine:
%   'loop'  — tp_algo_generalized.m (зсуви по одному, parfor по Δx);
%   'batch' — tp_algo_generalized_batch.m (зсуви пачками; GPU або CPU).
%   CFG.gen.useGPU: true | false | 'auto' (GPU, якщо MATLAB його бачить — canUseGPU).
%   Обидві реалізації дають однакові числа (перевірено: double — до 1e-14,
%   single — відносна різниця ~1e-5).

engine = 'loop';
if isfield(CFG.gen,'engine') && ~isempty(CFG.gen.engine), engine = lower(CFG.gen.engine); end

switch engine
    case 'loop'
        R = tp_algo_generalized(IMG, CFG, sampleName, step);
    case 'batch'
        useGPU = false;
        if isfield(CFG.gen,'useGPU')
            if ischar(CFG.gen.useGPU) || isstring(CFG.gen.useGPU)
                useGPU = strcmpi(CFG.gen.useGPU,'auto') && exist('canUseGPU','file') && canUseGPU();
            else
                useGPU = logical(CFG.gen.useGPU);
            end
        end
        CFG.gen.useGPU = useGPU;
        if isfield(CFG.gen,'precision') && strcmpi(CFG.gen.precision,'auto')
            if useGPU, CFG.gen.precision = 'single'; else, CFG.gen.precision = 'double'; end
        end
        R = tp_algo_generalized_batch(IMG, CFG, sampleName, step);
    otherwise
        error('tp_algo_generalized_run: невідомий CFG.gen.engine "%s"', engine);
end
end
