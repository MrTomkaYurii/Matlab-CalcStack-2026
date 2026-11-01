function [IMGm, info] = tp_phase_window(IMG, CFG, k)
% TP_PHASE_WINDOW  Фазова селекція ПОЛЯ (стаття, рівн. 20, п. 6–7, S9–S10)
%   ДО двоточкового розрахунку f_ik.
%   Для КОЖНОГО освітлення w окремо:
%       phi_xy^(w) = angle(Ey^(w)) - angle(Ex^(w)),  зведена в [0, 2*pi)
%   пікселі, де phi_xy^(w) виходить за межі [0, U_k] (U_k з
%   tp_phase_window_bounds), відкидаються — Ex^(w), Ey^(w) стають NaN
%   ЛИШЕ для цього освітлення. Далі tp_fik_pair рахує пари як завжди
%   (NaN-безпечно): пара випадає, якщо хоч одне потрібне освітлення
%   хоч в одній із двох точок поза своїм вікном.
%
%   CFG.phase.maskMode:
%     'perIllumination' (типово) — як у статті: кожне освітлення за СВОЄЮ phi_xy^(w)
%     'reference'                — одна спільна маска за phi_xy освітлення CFG.phase.refPol
%
%   [IMGm, info] = tp_phase_window(IMG, CFG, k)
%       IMGm : IMG з NaN поза вікном k
%       info : struct('index',k,'lower',0,'upper',U_k,'mode',..,
%                     'keptFrac', struct(<освітлення>) = частка збережених пікселів)

U = tp_phase_window_bounds(CFG);
tp_assert(k >= 1 && k <= numel(U), 'tp_phase_window: k=%d поза межами 1..%d', k, numel(U));
Uk = U(k);

mode = 'perIllumination';
if isfield(CFG.phase,'maskMode') && ~isempty(CFG.phase.maskMode), mode = CFG.phase.maskMode; end

pols = fieldnames(IMG);
IMGm = IMG;
keptFrac = struct();

switch lower(mode)
    case 'perillumination'
        for p = 1:numel(pols)
            P = IMG.(pols{p});
            mask = mod(angle(P.Ey) - angle(P.Ex), 2*pi) <= Uk;
            IMGm.(pols{p}).Ex(~mask) = NaN;
            IMGm.(pols{p}).Ey(~mask) = NaN;
            keptFrac.(pols{p}) = nnz(mask)/numel(mask);
        end
    case 'reference'
        refPol = CFG.phase.refPol;
        tp_assert(isfield(IMG, refPol), 'tp_phase_window: IMG не має каналу "%s"', refPol);
        mask = mod(angle(IMG.(refPol).Ey) - angle(IMG.(refPol).Ex), 2*pi) <= Uk;
        for p = 1:numel(pols)
            IMGm.(pols{p}).Ex(~mask) = NaN;
            IMGm.(pols{p}).Ey(~mask) = NaN;
            keptFrac.(pols{p}) = nnz(mask)/numel(mask);
        end
    otherwise
        error('tp_phase_window: невідомий CFG.phase.maskMode "%s"', mode);
end

info = struct('index', k, 'lower', 0, 'upper', Uk, 'mode', mode, 'keptFrac', keptFrac);
end
