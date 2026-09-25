function verify_block_B1_LB_0_90()
% VERIFY_BLOCK_B1_LB_0_90  Перевірка ЛИШЕ Блоку B.1 (LB_CB_rho/tp_B1_LB_0_90.m)
%   проти нативної комплексної арифметики MATLAB. Незалежна від решти
%   чотирьох блоків.
addpath('../LB_CB_rho');
rng(101); n = 100000; tol = 1e-9;

f34 = randn(n,1)+1i*randn(n,1);
f43 = randn(n,1)+1i*randn(n,1);

OUT = tp_B1_LB_0_90(f34, f43);
ref = log(f34./f43);

errMod = max(abs(OUT.mod - abs(ref)));
errArg = max(abs(wrapToPi(OUT.arg - angle(ref))));
errCplx = max(abs(OUT.cplx - ref));   % LB = Re + i*Im напряму (не лише mod/arg)
fprintf('LB_0_90 : |.| err=%.3e   arg err=%.3e   cplx err=%.3e\n', errMod, errArg, errCplx);
assert(errMod<tol && errArg<tol && errCplx<tol, 'tp_B1_LB_0_90.m mismatch vs log(f34/f43)');
fprintf('OK — tp_B1_LB_0_90.m verified independently.\n');
end
function a = wrapToPi(a), a = mod(a+pi,2*pi)-pi; end
