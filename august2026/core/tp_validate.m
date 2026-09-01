function [ok, reason] = tp_validate(D, CFG)
% TP_VALIDATE  Вирішує, чи варто зберігати 2D-розподіл.
%   Реалізує правило "якщо розподіл негодящий — не зберігати".
%   Повертає ok=false і причину, коли карта вироджена.

ok = true; reason = '';
if ~CFG.qc.enable, return; end

v = D(isfinite(D));                 % відкидаємо NaN/Inf
if isempty(v)
    ok = false; reason = 'all NaN/Inf'; return;
end
nanFrac = 1 - numel(v)/numel(D);
if nanFrac > CFG.qc.maxNaNfrac
    ok = false; reason = sprintf('NaN fraction %.2f > %.2f', nanFrac, CFG.qc.maxNaNfrac); return;
end
if std(v) < CFG.qc.minStd
    ok = false; reason = 'near-constant map'; return;
end
end
