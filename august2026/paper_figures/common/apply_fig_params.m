function FIG = apply_fig_params(FIG, cfgKey)
% APPLY_FIG_PARAMS  Накладає пер-фігурні перевизначення FIG.(cfgKey).params
%   поверх спільних значень FIG (глибоке рекурсивне злиття). Порожній
%   .params -> FIG без змін.
%
%   Напр. FIG.fig06_f33f44.params.mfr.qRange = -8:0.2:8  замінить лише
%   FIG.mfr.qRange для Fig6/f33f44, решту лишить як є.

if ~isfield(FIG, cfgKey) || ~isfield(FIG.(cfgKey), 'params'); return; end
P = FIG.(cfgKey).params;
if isempty(P) || ~isstruct(P) || isempty(fieldnames(P)); return; end
FIG = merge(FIG, P);
end

% ----------------------------------------------------------------------
function base = merge(base, over)
fn = fieldnames(over);
for i = 1:numel(fn)
    k = fn{i};
    if isstruct(over.(k)) && isfield(base, k) && isstruct(base.(k))
        base.(k) = merge(base.(k), over.(k));
    else
        base.(k) = over.(k);
    end
end
end
