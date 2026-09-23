function verify_block_B3_CB()
% VERIFY_BLOCK_B3_CB  Перевірка ЛИШЕ Блоку B.3 (LB_CB_rho/tp_B3_CB.m) проти
%   нативної комплексної арифметики MATLAB. Незалежна від решти чотирьох
%   блоків.
addpath('../LB_CB_rho');
rng(103); n = 100000; tol = 1e-9;

f23 = randn(n,1)+1i*randn(n,1);
f32 = randn(n,1)+1i*randn(n,1);

OUT = tp_B3_CB(f23, f32);
ref = log(f23./f32);

errMod = max(abs(OUT.mod - abs(ref)));
errArg = max(abs(wrapToPi(OUT.arg - angle(ref))));
fprintf('CB : |.| err=%.3e   arg err=%.3e\n', errMod, errArg);
assert(errMod<tol && errArg<tol, 'tp_B3_CB.m mismatch vs log(f23/f32)');
fprintf('OK — tp_B3_CB.m verified independently.\n');
end
function a = wrapToPi(a), a = mod(a+pi,2*pi)-pi; end
