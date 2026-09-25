function I = tp_sim_intensities(Ex, Ey)
% TP_SIM_INTENSITIES  Шість поляризаційних інтенсивностей з комплексних Ex,Ey.
%   ТІ САМІ формули, що були в july2026\simulation\tp_sim_speckle_BT.m (там
%   вони будувались одразу в генераторі; тепер генератор віддає поля, а
%   інтенсивності потрібні лише для рисунків етапу Sim 05).
I = struct();
I.I0    = abs(Ex).^2;
I.I90   = abs(Ey).^2;
I.I45   = 0.5 * abs(Ex + Ey).^2;
I.I135  = 0.5 * abs(Ex - Ey).^2;
I.Iprav = 0.5 * abs(Ex - 1i*Ey).^2;   % права циркулярна
I.Iliv  = 0.5 * abs(Ex + 1i*Ey).^2;   % ліва  циркулярна
end
