function verify_block_B4_rho()
% VERIFY_BLOCK_B4_RHO  Перевірка ЛИШЕ Блоку B.4 (LB_CB_rho/tp_B4_rho.m) проти
%   нативної комплексної арифметики MATLAB. Вхід — довільні комплексні
%   LB_0_90, LB_45_135 (як їх повертають tp_B1_LB_0_90.m/tp_B2_LB_45_135.m,
%   поле .cplx) — тут НЕ обчислюються з f_mn, блок перевіряється сам по
%   собі, незалежно від Блоків B.1-B.3.
addpath('../LB_CB_rho');
rng(104); n = 100000; tol = 1e-9;

LB0_90   = randn(n,1)+1i*randn(n,1);
LB45_135 = randn(n,1)+1i*randn(n,1);

OUT = tp_B4_rho(LB0_90, LB45_135);
ref = 0.5*atan(LB45_135 ./ LB0_90);

errMod = max(abs(OUT.mod - abs(ref)));
errArg = max(abs(wrapToPi(OUT.arg - angle(ref))));
errCplx = max(abs(OUT.cplx - ref));   % rho = P + iQ напряму (Re і Im окремо, не лише mod/arg)
fprintf('rho : |.| err=%.3e   arg err=%.3e   cplx err=%.3e\n', errMod, errArg, errCplx);
assert(errMod<tol && errArg<tol && errCplx<tol, 'tp_B4_rho.m mismatch vs 0.5*atan(LB45_135/LB0_90)');
fprintf('OK — tp_B4_rho.m verified independently.\n');
end
function a = wrapToPi(a), a = mod(a+pi,2*pi)-pi; end
