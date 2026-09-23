function verify_block_B2_LB_45_135()
% VERIFY_BLOCK_B2_LB_45_135  Перевірка ЛИШЕ Блоку B.2 (LB_CB_rho/tp_B2_LB_45_135.m)
%   проти нативної комплексної арифметики MATLAB. Незалежна від решти
%   чотирьох блоків.
addpath('../LB_CB_rho');
rng(102); n = 100000; tol = 1e-9;

f24 = randn(n,1)+1i*randn(n,1);
f42 = randn(n,1)+1i*randn(n,1);

OUT = tp_B2_LB_45_135(f24, f42);
ref = log(f24./f42);

errMod = max(abs(OUT.mod - abs(ref)));
errArg = max(abs(wrapToPi(OUT.arg - angle(ref))));
fprintf('LB_45_135 : |.| err=%.3e   arg err=%.3e\n', errMod, errArg);
assert(errMod<tol && errArg<tol, 'tp_B2_LB_45_135.m mismatch vs log(f24/f42)');
fprintf('OK — tp_B2_LB_45_135.m verified independently.\n');
end
function a = wrapToPi(a), a = mod(a+pi,2*pi)-pi; end
