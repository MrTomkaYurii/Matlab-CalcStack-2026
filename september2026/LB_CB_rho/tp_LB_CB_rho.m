function OUT = tp_LB_CB_rho(f23, f32, f24, f42, f34, f43)
% TP_LB_CB_rho  Крок B: тонкий оркестратор 5 НЕЗАЛЕЖНИХ блоків (кожен —
%   окремий файл, номер блоку в імені файлу, можна викликати й
%   перевіряти окремо):
%       Блок B.1  tp_B1_LB_0_90.m    LB_{0,90} = ln(f34/f43)
%       Блок B.2  tp_B2_LB_45_135.m  LB_{45,135} = ln(f24/f42)
%       Блок B.3  tp_B3_CB.m         CB = ln(f23/f32)
%       Блок B.4  tp_B4_rho.m        rho = (1/2) atan(LB_{45,135}/LB_{0,90})
%       Блок B.5  tp_B5_LB_total.m   LB = sqrt(LB_{0,90}^2 + LB_{45,135}^2)
%   (усі три через спільний примітив Блок B.0, tp_B0_cross_log_ratio.m)
%   rho і LB залежать лише від ГОТОВИХ LB_0_90.cplx / LB_45_135.cplx
%   (Re+i*Im логарифма-відношення) — НЕ від CB. CB не залежить ні від
%   чого, крім свого власного f23,f32.
%
%   Вхід (Крок A, tp_fik_pair.m — НЕ перераховується): f23,f32,f24,f42,
%        f34,f43, комплексні, однакового розміру (число або 2D-карта).
%   Вихід: OUT.LB_0_90, OUT.LB_45_135, OUT.CB, OUT.rho, OUT.LB — кожне
%        struct('mod',.,'arg',.,'cplx',.).

OUT = struct();
OUT.LB_0_90   = tp_B1_LB_0_90(f34, f43);
OUT.LB_45_135 = tp_B2_LB_45_135(f24, f42);
OUT.CB        = tp_B3_CB(f23, f32);
OUT.rho       = tp_B4_rho(OUT.LB_0_90.cplx, OUT.LB_45_135.cplx);
OUT.LB        = tp_B5_LB_total(OUT.LB_0_90.cplx, OUT.LB_45_135.cplx);
end
