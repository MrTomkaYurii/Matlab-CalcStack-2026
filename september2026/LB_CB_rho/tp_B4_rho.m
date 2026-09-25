function OUT = tp_B4_rho(LB0_90, LB45_135)
% TP_B4_RHO  Блок B.4 (зелена формула, Word стор.3): rho = (1/2) arctan( LB_{45,135} / LB_{0,90} ).
%   Незалежний блок — залежить лише від ГОТОВИХ комплексних LB_{0,90} і
%   LB_{45,135} (виходи B.1 / B.2, поле .cplx = Re + i*Im логарифма-
%   відношення), НЕ від CB чи LB. Можна викликати й перевіряти окремо.
%   Імена змінних = позначення з Word ("Співвідношення rho = ..."):
%
%       Word                              код
%       A1 + iB1 = Re_{34,43}+i*Im_{34,43}   Re_34_43, Im_34_43 ; A1, B1   (LB_{0,90},  ЗНАМЕННИК)
%       A2 + iB2 = Re_{24,42}+i*Im_{24,42}   Re_24_42, Im_24_42 ; A2, B2   (LB_{45,135}, ЧИСЕЛЬНИК)
%       X, Y                              X, Y
%       atan2( 2X/(1-X^2-Y^2) )           atan2_2X
%       ln[ (X^2+(1+Y)^2)/(X^2+(1-Y)^2) ] ln_XY
%       P = 1/4 atan2(...), Q = 1/8 ln[...]   P, Q      (rho = P + iQ)
%       |rho|, arg(rho)                   absRho, argRho
%   (У Word під "де" P,Q записані малими x,y — це X,Y; одруківка регістру.)
%
%   Вхід : LB0_90, LB45_135 — комплексні (число або 2D-карта).
%   Вихід: OUT = struct('mod',|rho|, 'arg',arg(rho), 'cplx',rho = P + iQ)
%
%   Ділення на (A1^2+B1^2)=0: СВІДОМО без епсилона (IEEE-754 NaN/Inf,
%   далі isfinite у візуалізації).

% Захист від мовчазного неявного розширення (N×1 з 1×N -> N×N): розміри мусять збігатися.
assert(isequal(size(LB0_90), size(LB45_135)), 'tp_B4_rho: LB0_90 і LB45_135 мають бути одного розміру');

% LB_{0,90} = Re_{34,43} + i*Im_{34,43} ;  LB_{45,135} = Re_{24,42} + i*Im_{24,42}
Re_34_43 = real(LB0_90);     Im_34_43 = imag(LB0_90);
Re_24_42 = real(LB45_135);   Im_24_42 = imag(LB45_135);
A1 = Re_34_43;   B1 = Im_34_43;     % Word: A1 + iB1  (знаменник)
A2 = Re_24_42;   B2 = Im_24_42;     % Word: A2 + iB2  (чисельник)

% LB_{45,135}/LB_{0,90} = (A2+iB2)/(A1+iB1) = X + iY
%   X = (A1*A2 + B1*B2)/(A1^2 + B1^2) ,   Y = (A1*B2 - A2*B1)/(A1^2 + B1^2)
X = (A1.*A2 + B1.*B2) ./ (A1.^2 + B1.^2);
Y = (A1.*B2 - A2.*B1) ./ (A1.^2 + B1.^2);

% rho = 1/4 atan2( 2X/(1-X^2-Y^2) ) + i * 1/8 ln[ (X^2+(1+Y)^2)/(X^2+(1-Y)^2) ]
atan2_2X = atan2( 2*X, 1 - X.^2 - Y.^2 );                  % atan2( 2X / (1 - X^2 - Y^2) )
ln_XY    = log( (X.^2 + (1+Y).^2) ./ (X.^2 + (1-Y).^2) );  % ln[ (X^2+(1+Y)^2) / (X^2+(1-Y)^2) ]
P = (1/4) * atan2_2X;     % Re(rho)
Q = (1/8) * ln_XY;        % Im(rho)

% |rho| = sqrt( {1/4 atan2(2X/(1-X^2-Y^2))}^2 + {1/8 ln[...]}^2 )
absRho = sqrt( ((1/4)*atan2_2X).^2 + ((1/8)*ln_XY).^2 );

% arg(rho) = atan4( ln[...] / atan2(2X/(1-X^2-Y^2)) )   -- у Word "atan4"
%   не стандартна функція. Розшифровка (claude_code_prompt_LB_CB_rho.md;
%   чисельно перевірено verify\verify_theory_formulas.m, розділ 4):
%   arg(rho) = atan2(Q,P) = atan2( ln_XY/8, atan2_2X/4 ) = atan2( ln_XY, 2*atan2_2X ).
argRho = atan2( ln_XY, 2*atan2_2X );

OUT = struct('mod', absRho, 'arg', argRho, 'cplx', P + 1i*Q);
end
