function verify_block_B5_LB_total()
% VERIFY_BLOCK_B5_LB_TOTAL  Перевірка ЛИШЕ Блоку B.5 (LB_CB_rho/tp_B5_LB_total.m)
%   проти нативної комплексної арифметики MATLAB. Вхід — довільні
%   комплексні LB_0_90, LB_45_135 — блок перевіряється сам по собі,
%   незалежно від решти.
addpath('../LB_CB_rho');
rng(105); n = 100000; tol = 1e-9;

LB0_90   = randn(n,1)+1i*randn(n,1);
LB45_135 = randn(n,1)+1i*randn(n,1);

OUT = tp_B5_LB_total(LB0_90, LB45_135);
ref = sqrt(LB0_90.^2 + LB45_135.^2);

errMod = max(abs(OUT.mod - abs(ref)));
errArg = max(abs(wrapToPi(OUT.arg - angle(ref))));
fprintf('LB : |.| err=%.3e   arg err=%.3e\n', errMod, errArg);
assert(errMod<tol && errArg<tol, 'tp_B5_LB_total.m mismatch vs sqrt(LB0_90^2+LB45_135^2)');
fprintf('OK — tp_B5_LB_total.m verified independently.\n');
end
function a = wrapToPi(a), a = mod(a+pi,2*pi)-pi; end
