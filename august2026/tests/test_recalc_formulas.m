function test_recalc_formulas(withData)
% TEST_RECALC_FORMULAS  Перевірка виправлень (RECALC_PLAN_2026-11.md).
%   test_recalc_formulas         % формули + моменти + реальні дані (якщо є)
%   test_recalc_formulas(false)  % без реальних даних
%   Кожна перевірка друкує OK або падає з assert.

if nargin < 1, withData = true; end
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root,'config'), genpath(fullfile(root,'core')), fullfile(root,'paper_figures','common'));
rng(1);
tol = 1e-10;

% ---------------------------------------------------------------- 1. f_ik
pols = tp_fik_pols();
n = 50;
A1 = struct(); A2 = struct();
for p = 1:numel(pols)
    A1.(pols{p}) = struct('Ex', crandn(n), 'Ey', crandn(n));
    A2.(pols{p}) = struct('Ex', crandn(n), 'Ey', crandn(n));
end
F = tp_fik_pair(A1, A2);
% пряме визначення (10), (13) по пікселю, незалежно від tp_sc_vector
err = 0;
for j = 1:n
    for p = 1:numel(pols)
        a = A1.(pols{p});  b = A2.(pols{p});
        E1 = [a.Ex(j); a.Ey(j)];  E2 = [b.Ex(j); b.Ey(j)];
        SC.(pols{p}) = [E1'*E2; E1(1)'*E2(1)-E1(2)'*E2(2); E1(1)'*E2(2)+E1(2)'*E2(1); ...
                        1i*(E1(2)'*E2(1)-E1(1)'*E2(2))];
    end
    M = [SC.in0+SC.in90, SC.in0-SC.in90, SC.in45-SC.in135, SC.inRC-SC.inLC] / 2;
    for i = 1:4
        for k = 1:4
            err = max(err, abs(F.(sprintf('f%d%d',i,k))(j) - M(i,k)));
        end
    end
end
assert(err < tol, 'f_ik != рівн. (10),(13): %.2e', err);
ok('f_ik = рівн. (10), (13) (пряме визначення)', err);

% f_i2 більше НЕ спряжене f_i1
d = max(abs(F.f12 - conj(F.f11)), [], 'all');
assert(d > 1e-3, 'f12 досі = conj(f11)');
ok('f_i2 != conj(f_i1)', d);

% r1 = r2: f_ik — звичайна матриця Мюллера джонсової матриці J (незалежно: A*kron(J,J*)*inv(A))
U = struct('in0',[1;0],'in90',[0;1],'in45',[1;1]/sqrt(2),'in135',[1;-1]/sqrt(2), ...
           'inRC',[1;1i]/sqrt(2),'inLC',[1;-1i]/sqrt(2));
Amat = [1 0 0 1; 1 0 0 -1; 0 1 1 0; 0 1i -1i 0];
err = 0;
for trial = 1:20
    J = crandn(2,2);
    B = struct();
    for p = 1:numel(pols)
        E = J * U.(pols{p});
        B.(pols{p}) = struct('Ex', E(1), 'Ey', E(2));
    end
    Fs = tp_fik_pair(B, B);
    Mref = real(Amat * kron(J, conj(J)) / Amat);
    for i = 1:4
        for k = 1:4
            err = max(err, abs(Fs.(sprintf('f%d%d',i,k)) - Mref(i,k)));
        end
    end
end
assert(err < 1e-9, 'f(r,r) != Мюллер(J): %.2e', err);
ok('f_ik(r,r) = матриця Мюллера J (A·kron(J,J*)·A^-1)', err);

% порожній зразок з різними скалярними множниками в точках: f = conj(g1)*g2 * I
g1 = crandn(1); g2 = crandn(1);
B1 = struct(); B2 = struct();
for p = 1:numel(pols)
    B1.(pols{p}) = struct('Ex', g1*U.(pols{p})(1), 'Ey', g1*U.(pols{p})(2));
    B2.(pols{p}) = struct('Ex', g2*U.(pols{p})(1), 'Ey', g2*U.(pols{p})(2));
end
Fi = tp_fik_pair(B1, B2);
err = 0;
for i = 1:4
    for k = 1:4
        err = max(err, abs(Fi.(sprintf('f%d%d',i,k)) - conj(g1)*g2*(i==k)));
    end
end
assert(err < tol, 'порожній зразок != conj(g1) g2 I: %.2e', err);
ok('порожній зразок: f = conj(g1)·g2·I', err);

% ---------------------------------------------- 2. generalized: batch = loop
CFG = cfg_TwoPoint();
CFG.crop.size = 20;  CFG.gen.maxDist = 4;  CFG.gen.posStep = 1;  CFG.gen.parallel = false;
IMG = struct();
for p = 1:numel(pols)
    IMG.(pols{p}) = struct('Ex', crandn(20), 'Ey', crandn(20));
end
IMG.in90.Ex(5,7) = complex(NaN);                     % NaN-пара має випадати однаково
Rl = tp_algo_generalized(IMG, CFG, 't', 1);
Cb = CFG;  Cb.gen.useGPU = false;  Cb.gen.precision = 'double';
Rb = tp_algo_generalized_batch(IMG, Cb, 't', 1);
err = 0;
for e = 1:numel(CFG.elements)
    a = Rl.data.step_1.(CFG.elements{e});  b = Rb.data.step_1.(CFG.elements{e});
    assert(isequal(isfinite(a.mod), isfinite(b.mod)), 'batch/loop: різні NaN (%s)', CFG.elements{e});
    m = isfinite(a.mod);
    err = max([err, max(abs(a.mod(m)-b.mod(m))), max(abs(a.cplx(m)-b.cplx(m)))]);
end
assert(err < 1e-9, 'batch != loop: %.2e', err);
ok('generalized: batch = loop', err);

% ------------------------------------------------ 3. кругові моменти (методика §5)
C = tp_circ_moments(repmat(0.7, 100, 1));
assert(all(abs(C.R - 1) < tol) && abs(C.V) < tol && abs(C.mu - 0.7) < tol);
ok('усі theta = theta0: R1..R4 = 1, V = 0, mu = theta0', max(abs(C.R-1)));

C = tp_circ_moments(deg2rad([179; -179]));
assert(abs(rad2deg(C.mu) - 180) < 1e-9 && abs(C.R(1) - 0.99985) < 1e-5 && abs(C.V - 0.00015) < 1e-5);
ok(sprintf('±179°: mu = %.4f°, R1 = %.5f, V = %.5f', rad2deg(C.mu), C.R(1), C.V), 0);

C = tp_circ_moments(repmat([0; pi], 50, 1));
assert(C.R(1) < 1e-12 && isnan(C.mu) && abs(C.R(2) - 1) < tol);
ok('0 і pi порівну: R1 = 0, mu не визначене, R2 = 1', C.R(1));

C = tp_circ_moments(repmat([0; pi/2; pi; 3*pi/2], 25, 1));
assert(all(C.R(1:3) < 1e-12) && abs(C.R(4) - 1) < tol);
ok('0, pi/2, pi, 3pi/2: R1 = R2 = R3 = 0, R4 = 1', max(C.R(1:3)));

th = 2*pi*rand(500,1) - pi;
C0 = tp_circ_moments(th);
C1 = tp_circ_moments(th + 2*pi*randi([-3 3], 500, 1));
assert(max(abs(C0.M - C1.M)) < 1e-9);
ok('theta + 2 pi l: M_p не змінюються', max(abs(C0.M - C1.M)));
C2 = tp_circ_moments(th + 0.9);
assert(max(abs(C0.R - C2.R)) < 1e-12 && max(abs(C2.M - exp(1i*(1:4)*0.9).*C0.M)) < 1e-12);
ok('поворот alpha: R_p незмінні, M_p -> exp(i p alpha) M_p', max(abs(C0.R - C2.R)));

% ------------------------------------------------ 4. степеневі (29) і Фішер
x = randn(1000,1);
[Z, m] = tp_power_moments(x);
assert(Z(4) >= 1 && Z(2) >= abs(Z(1)) && abs(Z(4) - m(4)/m(2)^2) < tol);
ok(sprintf('(29): Z4 = %.3f >= 1, Z2 >= |Z1|', Z(4)), 0);
Z = tp_power_moments(abs(x));
assert(Z(3) >= 1 && Z(4) >= 1);
ok(sprintf('(29) для модуля: Z3 = %.3f >= 1', Z(3)), 0);

w = angle(exp(1i*(1 + 0.6*randn(2e5,1))));         % згорнуте нормальне
[mu, ~, sk, ku] = tp_moments(w, true);
assert(abs(sk) < 0.02 && abs(ku) < 0.05 && abs(mu - 1) < 0.01);
ok(sprintf('Фішер, згорнуте нормальне: Z3c = %.3f, Z4c = %.3f ~ 0', sk, ku), 0);
[mu2, sd2, sk2, ku2] = tp_moments(mod(w, 2*pi), true);
[~, sd, ~, ~] = tp_moments(w, true);
assert(abs(mu2 - mu) < tol && abs(sd2 - sd) < tol && abs(sk2 - sk) < tol && abs(ku2 - ku) < tol);
ok('Фішер не залежить від гілки (-pi,pi] / [0,2pi)', 0);

% ------------------------------------------------ 5. реальні дані
if withData
    CFG = cfg_TwoPoint();
    if exist(CFG.paths.matRoot, 'dir') ~= 7
        fprintf('  [skip] реальні дані: немає %s\n', CFG.paths.matRoot);
    else
        CFG.crop.size = 60;
        [IMG, W] = tp_load_mat(CFG, 'Мозг', '1');      % зразок з битими каналами
        assert(isfield(IMG,'inLC') && isfield(IMG,'inRC'));
        for p = 1:numel(pols)
            assert(~any(abs(IMG.(pols{p}).Ex(:)) == 0) && ~any(abs(IMG.(pols{p}).Ey(:)) == 0), ...
                   'нульові пікселі не відкинуті (%s)', pols{p});
        end
        ok(sprintf('Мозг/1: нулі -> NaN (%d попереджень про биті канали)', numel(W)), 0);

        IMG = tp_load_mat(CFG, 'Серце', '2');
        Ro = tp_algo_orthogonal(IMG, CFG, 't');
        f11 = Ro.data.OX_step_1.f11.cplx;  f12 = Ro.data.OX_step_1.f12.cplx;
        m = isfinite(f11);
        d = max(abs(f12(m) - conj(f11(m))) ./ abs(f11(m)));
        assert(d > 1e-3, 'реальні дані: f12 = conj(f11)');
        ok('Серце/2, orthogonal: f12 != conj(f11)', d);

        [IMGk, info] = tp_phase_window(IMG, CFG, CFG.phase.numWindows);
        ph = mod(angle(IMGk.in0.Ey) - angle(IMGk.in0.Ex), 2*pi);
        assert(all(ph(isfinite(ph)) <= info.upper + 1e-12));
        kf = cell2mat(struct2cell(info.keptFrac));
        ok(sprintf('маска [0, %.2fpi]: phi_xy у вікні, збережено %.1f..%.1f%%', ...
                   info.upper/pi, 100*min(kf), 100*max(kf)), 0);

        Cx = CFG;  Cx.fik.phaseRef = 'x';
        IMGx = tp_load_mat(Cx, 'Серце', '2');
        assert(max(abs(imag(IMGx.in0.Ex(:)))) < 1e-12);
        ok('phaseRef = ''x'': Ex дійсне (фаза x = 0)', 0);
    end
end
fprintf('\nУСІ ПЕРЕВІРКИ ПРОЙДЕНО\n');
end

% ----------------------------------------------------------------------
function z = crandn(varargin)
z = complex(randn(varargin{:}), randn(varargin{:}));
end

function ok(msg, v)
fprintf('  OK  %-62s  (%.1e)\n', msg, v);
end
