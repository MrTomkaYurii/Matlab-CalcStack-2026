function OUT = tp_B2_LB_45_135(f24, f42)
% TP_LB_45_135  Блок B.2 (зелена формула): LB_{45,135} = ln(f24/f42).
%   Незалежний блок — можна викликати й перевіряти окремо від решти
%   чотирьох (LB_0_90, CB, rho, LB). Єдина залежність — спільний
%   примітив B.0, tp_cross_log_ratio.m.
%
%   Вхід : f24, f42 — комплексні (число або 2D-карта, з tp_fik_pair.m,
%          Крок A; тут НЕ перераховуються).
%   Вихід: OUT = struct('mod',|LB_45,135|, 'arg',arg(LB_45,135), 'cplx',.)

A24 = real(f24); B24 = imag(f24);
A42 = real(f42); B42 = imag(f42);

[~, ~, mod_, arg_] = tp_B0_cross_log_ratio(A24,B24, A42,B42);

OUT = struct('mod', mod_, 'arg', arg_, 'cplx', mod_ .* exp(1i*arg_));
end
