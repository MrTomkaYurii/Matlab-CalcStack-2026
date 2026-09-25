function [Se, info] = tp_phase_window_element(S, CFG, k)
% TP_PHASE_WINDOW_ELEMENT  Застосовує k-те фазове вікно ДО ВЖЕ ПОРАХОВАНОГО
%   двоточкового елемента f_ik — НА ВІДМІНУ від старого tp_phase_window.m
%   (яке ріже пікселі СИРОГО вхідного поля Ex,Ey ОДНОГО каналу CFG.phase.refPol
%   ДО двоточкового зрізу, спільно для всіх 16 елементів): тут критерій —
%   власний arg(f_ik) ЦЬОГО КОНКРЕТНОГО елемента, ПІСЛЯ повного розрахунку.
%   Причина зміни: deltaRef старої схеми алгебраїчно НЕ входить у формулу
%   f_i1/f_i2/f_i3 (лише f_i4 через inRC, tp_fik_pair.m розд.4) — тому
%   старе вікно для 12 із 16 елементів не мало жодного зв'язку з величиною,
%   яку рахували (перевірено емпірично: стат. моменти не мінялись між
%   вікнами). Нова версія прив'язана до САМОГО елемента за конструкцією.
%
%   Межі вікна — ЯК У ТЗ: [0, U_k], ЛІВА межа ЗАВЖДИ 0, права U_k звужується
%   від 2.00pi (k=1, фактично без фільтра) до 0.25pi (k=numWindows,
%   найвужче) — вікно стягується до фази 0, а НЕ до -pi/180°.
%   arg(f_ik) з angle() лежить у (-pi,pi], тому спершу переводимо у [0,2pi)
%   (mod 2*pi, тобто "від'ємні -> +2pi", як для старого deltaRef), і ЛИШЕ
%   ПОТІМ ріжемо [0, U_k]. (Попередня версія цього файлу різала
%   [-pi, -pi+U_k] — та сама ШИРИНА, але стягувалась до -pi/180°, а не до
%   0° — це не відповідало ТЗ; виправлено.)
%
%   S : struct('cplx',complex NxN, 'mod',abs(cplx), 'arg',angle(cplx)) —
%       ОДИН елемент, ПОВНИЙ (немаскований) результат алгоритму/напряму/
%       кроку (те, що виробляють tp_algo_orthogonal/XY/polar/generalized).
%   [Se, info] = tp_phase_window_element(S, CFG, k)
%       Se   : той самий struct, з NaN у .cplx/.mod/.arg поза вікном
%       info : struct('index',k,'lower',..,'upper',..,'keptFrac',..)

tp_assert(isstruct(S) && all(isfield(S, {'cplx','mod','arg'})), ...
    'tp_phase_window_element: S має бути struct(''cplx'',''mod'',''arg'')');

U = tp_phase_window_bounds(CFG);
tp_assert(k >= 1 && k <= numel(U), 'tp_phase_window_element: k=%d поза межами 1..%d', k, numel(U));

lower = 0;
upper = U(k);

validBefore = isfinite(S.arg);
% Симетрична маска навколо нуля: від -U/2 до U/2. Аргумент лишається у [-pi, pi].
mask = validBefore & (S.arg >= -upper/2) & (S.arg <= upper/2);

Se = S;
Se.cplx(~mask) = NaN;
Se.mod(~mask)  = NaN;
Se.arg(~mask)  = NaN;

nBefore = nnz(validBefore);
keptFrac = NaN;
if nBefore > 0
    keptFrac = nnz(mask) / nBefore;
end
info = struct('index', k, 'lower', lower, 'upper', upper, 'keptFrac', keptFrac);
end
