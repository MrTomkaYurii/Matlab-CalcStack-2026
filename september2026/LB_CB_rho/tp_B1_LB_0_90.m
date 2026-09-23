function OUT = tp_B1_LB_0_90(f34, f43)
% TP_LB_0_90  Блок B.1 (зелена формула): LB_{0,90} = ln(f34/f43).
%   Незалежний блок — можна викликати й перевіряти окремо від решти
%   чотирьох (LB_45_135, CB, rho, LB). Єдина залежність — спільний
%   примітив B.0, tp_cross_log_ratio.m.
%
%   Вхід : f34, f43 — комплексні (число або 2D-карта, з tp_fik_pair.m,
%          Крок A; тут НЕ перераховуються).
%   Вихід: OUT = struct('mod',|LB_0,90|, 'arg',arg(LB_0,90), 'cplx',.)

A34 = real(f34); B34 = imag(f34);
A43 = real(f43); B43 = imag(f43);

[~, ~, mod_, arg_] = tp_B0_cross_log_ratio(A34,B34, A43,B43);

OUT = struct('mod', mod_, 'arg', arg_, 'cplx', mod_ .* exp(1i*arg_));
end
