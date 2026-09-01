function U = tp_phase_window_bounds(CFG)
% TP_PHASE_WINDOW_BOUNDS  Верхні межі фазових вікон [0, U_k], k = 1..N.
%   За ТЗ: N=10 вікон, звужуються від [0, 2pi] (k=1, фактично без фільтра)
%   до [0, 0.25*pi] (k=N, найвужче) — рівномірно спадний ряд верхніх меж.
%   Нижня межа всіх вікон завжди 0.
%
%   U = tp_phase_window_bounds(CFG)  ->  1 x CFG.phase.numWindows double

U = linspace(CFG.phase.upperMax, CFG.phase.upperMin, CFG.phase.numWindows);
end
