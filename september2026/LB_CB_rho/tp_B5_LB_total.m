function OUT = tp_B5_LB_total(LB0_90, LB45_135)
% TP_LB_TOTAL  Блок B.5 (зелена формула): LB = sqrt( LB_{0,90}^2 + LB_{45,135}^2 ).
%   Незалежний блок — залежить лише від ГОТОВИХ комплексних LB_{0,90} і
%   LB_{45,135} (виходи tp_LB_0_90.m / tp_LB_45_135.m, поле .cplx), НЕ від
%   CB чи rho. Можна викликати й перевіряти окремо.
%
%   Вхід : LB0_90, LB45_135 — комплексні (число або 2D-карта): A1+iB1, A2+iB2
%   Вихід: OUT = struct('mod',|LB|, 'arg',arg(LB), 'cplx',.)

A1 = real(LB0_90);   B1 = imag(LB0_90);
A2 = real(LB45_135); B2 = imag(LB45_135);

C = A1.^2 - B1.^2 + A2.^2 - B2.^2;
D = 2*(A1.*B1 + A2.*B2);

mod_ = (C.^2 + D.^2) .^ 0.25;
arg_ = 0.5 * atan2(D, C);

OUT = struct('mod', mod_, 'arg', arg_, 'cplx', mod_ .* exp(1i*arg_));
end
