function verify_known_values_and_edges()
% VERIFY_KNOWN_VALUES_AND_EDGES  Перевірка блоків Кроку B на значеннях, які
%   легко порахувати ВРУЧНУ (незалежно від будь-якої програмної арифметики),
%   і на крайових випадках (ділення на нуль, розміри, 2D-карта).
%   Доповнює verify_block_B*.m (вони порівнюють з нативним log/atan/sqrt на
%   випадкових даних).
addpath('../LB_CB_rho');
tol = 1e-12;

% ---- 1) ln(z1/z2) для відомих відношень: B.1, B.2, B.3 мають однакову алгебру ----
% z1/z2 = e      ->  ln = 1            : Re=1,  Im=0    => |.|=1,  arg=0
% z1/z2 = i      ->  ln = i*pi/2       : Re=0,  Im=pi/2 => |.|=pi/2, arg=pi/2
% z1/z2 = -1     ->  ln = i*pi         : Re=0,  Im=pi   => |.|=pi, arg=pi/2
% z1/z2 = 1      ->  ln = 0            : |.|=0
z2 = [1+0i; 2+1i; 1+0i; 3-2i];
z1 = z2 .* [exp(1); 1i; -1; 1];
expected_cplx = [1; 1i*pi/2; 1i*pi; 0];
expected_mod  = [1; pi/2;    pi;    0];
expected_arg  = [0; pi/2;    pi/2;  0];
blocks = {@tp_B1_LB_0_90, @tp_B2_LB_45_135, @tp_B3_CB};
names  = {'B.1','B.2','B.3'};
for b = 1:3
    O = blocks{b}(z1, z2);
    e1 = max(abs(O.cplx - expected_cplx));
    e2 = max(abs(O.mod  - expected_mod));
    e3 = max(abs(O.arg(1:3) - expected_arg(1:3)));   % arg для 0 (останній) не перевіряється: atan2(0,0)=0 за конвенцією
    fprintf('%s known ratios (e, i, -1, 1):  cplx err=%.2e  mod err=%.2e  arg err=%.2e\n', names{b}, e1, e2, e3);
    assert(e1<tol && e2<tol && e3<tol, '%s: mismatch on hand-computable values', names{b});
end

% ---- 2) rho = 1/2 atan(w) для відомих w = LB45/LB0 ----------------------------
% w = 0    (LB45=0, LB0=1)  -> rho = 0
% w = 1    (LB45=LB0=1)     -> rho = 1/2*atan(1) = pi/8
% w = 0.5  (LB45=1, LB0=2)  -> rho = 1/2*atan(0.5)
O = tp_B4_rho([1; 1; 2], [0; 1; 1]);
expected = [0; pi/8; 0.5*atan(0.5)];
e = max(abs(O.cplx - expected));
fprintf('B.4 known ratios (0, 1, 0.5):  cplx err=%.2e\n', e);
assert(e<tol, 'B.4: mismatch on hand-computable values');

% ---- 3) LB = sqrt(LB0^2+LB45^2): піфагорова трійка ---------------------------
% LB0=3, LB45=4 (обидва дійсні) -> LB = sqrt(9+16) = 5.  |.|=5, arg=0
% LB0=1i, LB45=0                -> LB = sqrt(-1) = i.    |.|=1, arg=pi/2
O = tp_B5_LB_total([3; 1i], [4; 0]);
e = max(abs(O.cplx - [5; 1i])); em = max(abs(O.mod - [5; 1])); ea = max(abs(O.arg - [0; pi/2]));
fprintf('B.5 known values (3,4 -> 5;  i,0 -> i):  cplx err=%.2e  mod err=%.2e  arg err=%.2e\n', e, em, ea);
assert(e<tol && em<tol && ea<tol, 'B.5: mismatch on hand-computable values');

% ---- 4) крайові випадки: ділення на нуль -> NaN/Inf БЕЗ помилки --------------
O = tp_B1_LB_0_90(1+1i, 0);          % знаменник = 0
assert(~isfinite(O.mod), 'B.1: z2=0 має давати не-скінченне |LB| (Inf/NaN), без винятку');
O = tp_B4_rho(0, 1);                 % LB0_90 = 0 -> X,Y = Inf/NaN
assert(~isfinite(O.mod), 'B.4: LB0_90=0 має давати не-скінченне |rho|, без винятку');
fprintf('Division by zero: no exception, non-finite result (by design)  OK\n');

% ---- 5) захист розмірів: N×1 проти 1×N НЕ мовчки розширюється до N×N --------
threw = false;
try, tp_B1_LB_0_90(ones(3,1), ones(1,3)); catch, threw = true; end
assert(threw, 'B.1: розбіжність розмірів мусить давати помилку, а не неявне розширення');
threw = false;
try, tp_B4_rho(ones(3,1), ones(1,3)); catch, threw = true; end
assert(threw, 'B.4: розбіжність розмірів мусить давати помилку');
fprintf('Size mismatch (Nx1 vs 1xN): rejected with an error  OK\n');

% ---- 6) 2D-карта: результат має ту саму форму, що вхід ----------------------
rng(1); M = randn(7,5) + 1i*randn(7,5); N = randn(7,5) + 1i*randn(7,5);
O = tp_B1_LB_0_90(M, N);
assert(isequal(size(O.mod), [7 5]) && isequal(size(O.arg), [7 5]) && isequal(size(O.cplx), [7 5]), ...
    'B.1: форма виходу не збігається з формою 2D-входу');
fprintf('2D map in -> 2D map out (7x5)  OK\n');

fprintf('\nOK — known values, edge cases, size guard verified.\n');
end
