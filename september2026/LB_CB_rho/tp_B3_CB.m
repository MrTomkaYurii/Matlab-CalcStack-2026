function OUT = tp_B3_CB(f23, f32)
% TP_CB  Блок B.3 (зелена формула): CB = ln(f23/f32).
%   Незалежний блок — можна викликати й перевіряти окремо від решти
%   чотирьох (LB_0_90, LB_45_135, rho, LB). Єдина залежність — спільний
%   примітив B.0, tp_cross_log_ratio.m.
%
%   Вхід : f23, f32 — комплексні (число або 2D-карта, з tp_fik_pair.m,
%          Крок A; тут НЕ перераховуються).
%   Вихід: OUT = struct('mod',|CB|, 'arg',arg(CB), 'cplx',.)

A23 = real(f23); B23 = imag(f23);
A32 = real(f32); B32 = imag(f32);

[~, ~, mod_, arg_] = tp_B0_cross_log_ratio(A23,B23, A32,B32);

OUT = struct('mod', mod_, 'arg', arg_, 'cplx', mod_ .* exp(1i*arg_));
end
