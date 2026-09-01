function [IMGm, info] = tp_phase_window(IMG, CFG, k)
% TP_PHASE_WINDOW  Застосовує k-те фазове вікно до комплексного поля IMG.
%   Опорна фаза (одна, спільна для всіх освітлень — Етап 1 ТЗ):
%       delta_ref = angle(Ey) - angle(Ex)   каналу CFG.phase.refPol (типово inRC —
%       праве циркулярне, азимутально інваріантне; див. cfg_TwoPoint.m)
%   нормується в [0, 2*pi), і пікселі, де delta_ref виходить за межі
%   [0, U_k] (U_k з tp_phase_window_bounds), відкидаються — Ex,Ey СТАЮТЬ NaN
%   в УСІХ освітленнях (спільна маска). Downstream-формули (tp_fik_pair) і
%   так NaN-безпечні, тож жодних інших змін не потрібно: пара точок
%   рахується, лише якщо ОБИДВІ точки лишились валідними.
%
%   [IMGm, info] = tp_phase_window(IMG, CFG, k)
%       IMGm : IMG з масками NaN поза вікном k
%       info : struct('index',k,'lower',0,'upper',U_k,'keptFrac',...)
%              keptFrac — частка пікселів, що лишились у вікні (для QC/логів)

refPol = CFG.phase.refPol;
tp_assert(isfield(IMG, refPol), 'tp_phase_window: IMG не має каналу "%s"', refPol);

U = tp_phase_window_bounds(CFG);
tp_assert(k >= 1 && k <= numel(U), 'tp_phase_window: k=%d поза межами 1..%d', k, numel(U));
Uk = U(k);

deltaRef = mod(angle(IMG.(refPol).Ey) - angle(IMG.(refPol).Ex), 2*pi);
mask = deltaRef <= Uk;

IMGm = IMG;
pols = fieldnames(IMG);
for p = 1:numel(pols)
    IMGm.(pols{p}).Ex(~mask) = NaN;
    IMGm.(pols{p}).Ey(~mask) = NaN;
end

info = struct('index', k, 'lower', 0, 'upper', Uk, 'keptFrac', nnz(mask)/numel(mask), ...
              'deltaRef', deltaRef, 'mask', mask);
end
