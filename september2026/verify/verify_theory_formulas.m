function verify_theory_formulas()
% VERIFY_THEORY_FORMULAS  Numerical cross-check of every green-boxed formula
%   in techn-zavd\Теорія поляризаційно-кореляційна томографія.docx against
%   MATLAB's native complex arithmetic (log, atan, sqrt, abs, angle).
%   Pure math verification -- no dependency on august2026 data or on how
%   ΔA_mn/ΔB_mn are actually produced upstream.
%
%   Run:  verify_theory_formulas
%   Prints max abs error for every formula over many random trials. All
%   should be ~1e-12 (double precision roundoff) if the transcription is
%   correct.

rng(12345);
nTrials = 200000;
tol = 1e-9;

fprintf('=== 1) LB_{0,90} = ln(f34^c / f43^c) : |.| and arg(.) ===\n');
check_log_ratio(nTrials, tol);

fprintf('\n=== 2) rho = (1/2) atan(LB_{45,135} / LB_{0,90}) : |.| and arg(.) ===\n');
check_rho(nTrials, tol);

fprintf('\n=== 3) LB = sqrt(LB_{0,90}^2 + LB_{45,135}^2) : |.| and arg(.) ===\n');
check_LB_total(nTrials, tol);

fprintf('\n=== 4) atan4 reconciliation for arg(rho) ===\n');
check_atan4(nTrials, tol);

fprintf('\nAll checks done.\n');
end

% ------------------------------------------------------------------
function check_log_ratio(n, tol)
% numerator z_num = a + i b ,  denominator z_den = c + i d  (random reals)
a = randn(n,1); b = randn(n,1); c = randn(n,1); d = randn(n,1);

% --- doc formula (page 1), literal transcription ---
Re = 0.5*log( (a.^2+b.^2) ./ (c.^2+d.^2) );
Im = atan2( b.*c - a.*d, a.*c + b.*d );
magDoc = sqrt(Re.^2 + Im.^2);
argDoc = atan2(Im, Re);

% --- native reference ---
w = log( (a+1i*b) ./ (c+1i*d) );
ReRef = real(w); ImRef = imag(w);
magRef = abs(w); argRef = angle(w);

fprintf('  Re  : max abs err = %.3e\n', max(abs(Re-ReRef)));
fprintf('  Im  : max abs err = %.3e\n', max(abs(Im-ImRef)));
fprintf('  |LB0,90| : max abs err = %.3e\n', max(abs(magDoc-magRef)));
fprintf('  arg[LB0,90] : max abs err = %.3e\n', max(abs(wrapToPi(argDoc-argRef))));
assert(max(abs(Re-ReRef))<tol && max(abs(Im-ImRef))<tol, 'Re/Im mismatch');
assert(max(abs(magDoc-magRef))<tol, '|LB0,90| mismatch');
assert(max(abs(wrapToPi(argDoc-argRef)))<tol, 'arg[LB0,90] mismatch');
fprintf('  -> OK, formulas (1)/(2)/(3) Re/Im/mag/arg boxes are algebraically exact.\n');
end

% ------------------------------------------------------------------
function check_rho(n, tol)
% LB_{0,90} = A1+iB1 (den),  LB_{45,135} = A2+iB2 (num)  -- random reals,
% but keep away from A1=B1=0 (division) and from branch points of atan
% (z = +-1i) by construction (random reals a.s. avoid them).
A1 = randn(n,1); B1 = randn(n,1);
A2 = randn(n,1); B2 = randn(n,1);

% --- X, Y (doc, page 3) ---
X = (A1.*A2 + B1.*B2) ./ (A1.^2 + B1.^2);
Y = (A1.*B2 - A2.*B1) ./ (A1.^2 + B1.^2);

% cross-check X,Y against direct complex division
Zref = (A2+1i*B2) ./ (A1+1i*B1);
fprintf('  X : max abs err vs real(Zref) = %.3e\n', max(abs(X-real(Zref))));
fprintf('  Y : max abs err vs imag(Zref) = %.3e\n', max(abs(Y-imag(Zref))));

% --- rho, doc formula: Re/Im parts, magnitude ---
P = 0.25*atan2(2*X, 1-X.^2-Y.^2);
Q = 0.125*log( (X.^2+(1+Y).^2) ./ (X.^2+(1-Y).^2) );
magDoc = sqrt(P.^2+Q.^2);

% --- native reference: rho = 0.5*atan(X+iY) ---
rhoRef = 0.5*atan(X+1i*Y);
fprintf('  Re(rho) P : max abs err = %.3e\n', max(abs(P-real(rhoRef))));
fprintf('  Im(rho) Q : max abs err = %.3e\n', max(abs(Q-imag(rhoRef))));
fprintf('  |rho| : max abs err = %.3e\n', max(abs(magDoc-abs(rhoRef))));
assert(max(abs(P-real(rhoRef)))<tol, 'Re(rho) mismatch');
assert(max(abs(Q-imag(rhoRef)))<tol, 'Im(rho) mismatch');
assert(max(abs(magDoc-abs(rhoRef)))<tol, '|rho| mismatch');
fprintf('  -> OK, P=Re(rho), Q=Im(rho), |rho| boxes are algebraically exact.\n');
fprintf('  -> arg(rho) = atan2(Q,P) is therefore the correct/unambiguous formula\n');
fprintf('     (see part 4 for how the doc''s literal "atan4(...)" box reconciles).\n');
end

% ------------------------------------------------------------------
function check_LB_total(n, tol)
A1 = randn(n,1); B1 = randn(n,1);
A2 = randn(n,1); B2 = randn(n,1);

C = A1.^2 - B1.^2 + A2.^2 - B2.^2;
D = 2*(A1.*B1 + A2.*B2);

magDoc = ( C.^2 + D.^2 ) .^ 0.25;
argDoc = 0.5*atan2(D, C);

LBref = sqrt( (A1+1i*B1).^2 + (A2+1i*B2).^2 );

fprintf('  C+iD vs (A1+iB1)^2+(A2+iB2)^2 : max abs err = %.3e\n', ...
    max(abs((C+1i*D) - ((A1+1i*B1).^2+(A2+1i*B2).^2))));
fprintf('  |LB| : max abs err = %.3e\n', max(abs(magDoc-abs(LBref))));
fprintf('  arg(LB) : max abs err = %.3e\n', max(abs(wrapToPi(argDoc-angle(LBref)))));
assert(max(abs(magDoc-abs(LBref)))<tol, '|LB| mismatch');
assert(max(abs(wrapToPi(argDoc-angle(LBref))))<tol, 'arg(LB) mismatch');
fprintf('  -> OK, |LB| and arg(LB) boxes are algebraically exact (principal sqrt).\n');
end

% ------------------------------------------------------------------
function check_atan4(n, tol)
A1 = randn(n,1); B1 = randn(n,1);
A2 = randn(n,1); B2 = randn(n,1);
X = (A1.*A2 + B1.*B2) ./ (A1.^2 + B1.^2);
Y = (A1.*B2 - A2.*B1) ./ (A1.^2 + B1.^2);

rhoRef = 0.5*atan(X+1i*Y);
argRef = angle(rhoRef);

num = log( (X.^2+(1+Y).^2) ./ (X.^2+(1-Y).^2) );   % = 8*Q
den = atan2(2*X, 1-X.^2-Y.^2);                       % = 4*P

% Hypothesis: atan4(num,den) := atan2(num/2, den)  ==  atan2(4Q,4P) == atan2(Q,P)
argHyp = atan2(num/2, den);

err = max(abs(wrapToPi(argHyp - argRef)));
fprintf('  hypothesis atan4(num,den) := atan2(num/2, den):  max abs err = %.3e\n', err);
if err < tol
    fprintf('  -> CONFIRMED: atan4(a,b) == atan2(a/2, b) reconciles the doc''s arg(rho) box\n');
    fprintf('     exactly with arg(rho) = atan2(Q,P) (Q=Im(rho), P=Re(rho)).\n');
else
    fprintf('  -> hypothesis REJECTED, needs another candidate.\n');
end
end

% ------------------------------------------------------------------
function a = wrapToPi(a)
a = mod(a+pi, 2*pi) - pi;
end
