function verify_tp_LB_CB_rho()
% VERIFY_TP_LB_CB_RHO  End-to-end check of LB_CB_rho/tp_LB_CB_rho.m (the
%   ACTUAL function, not just the paper formulas) against MATLAB's native
%   complex log/atan/sqrt, using random complex f23,f32,f24,f42,f34,f43
%   (as if they were real tp_fik_pair.m output). All errors should be at
%   double-precision roundoff (~1e-12) if the transcription is exact.

addpath('../LB_CB_rho');
rng(7);
n = 100000;
tol = 1e-9;

f23 = randn(n,1)+1i*randn(n,1); f32 = randn(n,1)+1i*randn(n,1);
f24 = randn(n,1)+1i*randn(n,1); f42 = randn(n,1)+1i*randn(n,1);
f34 = randn(n,1)+1i*randn(n,1); f43 = randn(n,1)+1i*randn(n,1);

OUT = tp_LB_CB_rho(f23, f32, f24, f42, f34, f43);

% --- reference via native complex arithmetic ---
LB0_90_ref   = log(f34./f43);
LB45_135_ref = log(f24./f42);
CB_ref       = log(f23./f32);
rho_ref      = 0.5*atan(LB45_135_ref ./ LB0_90_ref);
LB_ref       = sqrt(LB0_90_ref.^2 + LB45_135_ref.^2);

fprintf('LB_0_90   : |.| err=%.3e  arg err=%.3e\n', ...
    max(abs(OUT.LB_0_90.mod-abs(LB0_90_ref))), max(abs(wrapToPi(OUT.LB_0_90.arg-angle(LB0_90_ref)))));
fprintf('LB_45_135 : |.| err=%.3e  arg err=%.3e\n', ...
    max(abs(OUT.LB_45_135.mod-abs(LB45_135_ref))), max(abs(wrapToPi(OUT.LB_45_135.arg-angle(LB45_135_ref)))));
fprintf('CB        : |.| err=%.3e  arg err=%.3e\n', ...
    max(abs(OUT.CB.mod-abs(CB_ref))), max(abs(wrapToPi(OUT.CB.arg-angle(CB_ref)))));
fprintf('rho       : |.| err=%.3e  arg err=%.3e\n', ...
    max(abs(OUT.rho.mod-abs(rho_ref))), max(abs(wrapToPi(OUT.rho.arg-angle(rho_ref)))));
fprintf('LB        : |.| err=%.3e  arg err=%.3e\n', ...
    max(abs(OUT.LB.mod-abs(LB_ref))), max(abs(wrapToPi(OUT.LB.arg-angle(LB_ref)))));

errs = [ max(abs(OUT.LB_0_90.mod-abs(LB0_90_ref)))
         max(abs(wrapToPi(OUT.LB_0_90.arg-angle(LB0_90_ref))))
         max(abs(OUT.LB_45_135.mod-abs(LB45_135_ref)))
         max(abs(wrapToPi(OUT.LB_45_135.arg-angle(LB45_135_ref))))
         max(abs(OUT.CB.mod-abs(CB_ref)))
         max(abs(wrapToPi(OUT.CB.arg-angle(CB_ref))))
         max(abs(OUT.rho.mod-abs(rho_ref)))
         max(abs(wrapToPi(OUT.rho.arg-angle(rho_ref))))
         max(abs(OUT.LB.mod-abs(LB_ref)))
         max(abs(wrapToPi(OUT.LB.arg-angle(LB_ref)))) ];

% .cplx усіх 5 виходів проти нативних комплексних еталонів (Re і Im разом)
errsCplx = [ max(abs(OUT.LB_0_90.cplx   - LB0_90_ref))
             max(abs(OUT.LB_45_135.cplx - LB45_135_ref))
             max(abs(OUT.CB.cplx        - CB_ref))
             max(abs(OUT.rho.cplx       - rho_ref))
             max(abs(OUT.LB.cplx        - LB_ref)) ];
fprintf('cplx err (LB_0_90, LB_45_135, CB, rho, LB): %s\n', sprintf('%.2e  ', errsCplx));
errs = [errs; errsCplx];

assert(all(errs < tol), 'tp_LB_CB_rho.m: mismatch vs native complex arithmetic');
fprintf('\nALL 10 OUTPUTS (mod, arg) + 5 cplx MATCH native complex log/atan/sqrt to <%.0e. tp_LB_CB_rho.m is verified.\n', tol);
end

function a = wrapToPi(a)
a = mod(a+pi, 2*pi) - pi;
end
