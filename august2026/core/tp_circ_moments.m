function S = tp_circ_moments(theta)
% TP_CIRC_MOMENTS  Нецентральні тригонометричні моменти аргументу
%   (методика перерахунку, розд. 4, рівн. (6)-(10)):
%     M_p = mean(exp(i*p*theta)) = C_p + i*S_p,   R_p = |M_p|,   p = 1..4
%     mu = atan2(S_1, C_1),  V = 1 - R_1,  sigma_circ = sqrt(-2 ln R_1)
%   Рівні ваги пікселів; theta — радіани, без NaN (фільтрує викликаюча сторона).
%   Не залежить від гілки запису фази ((-pi,pi] чи [0,2pi)).
%
%   S : struct('K',..,'C',[1x4],'S',[1x4],'R',[1x4],'M',[1x4 complex],
%              'mu',..(у [0,2pi)),'V',..,'sigma',..)

theta = theta(:);
K = numel(theta);
S = struct('K', K, 'C', nan(1,4), 'S', nan(1,4), 'R', nan(1,4), 'M', complex(nan(1,4)), ...
           'mu', NaN, 'V', NaN, 'sigma', NaN);
if K < 1, return; end

for p = 1:4
    S.C(p) = mean(cos(p*theta));
    S.S(p) = mean(sin(p*theta));
end
S.M = complex(S.C, S.S);
S.R = abs(S.M);
S.mu = mod(atan2(S.S(1), S.C(1)), 2*pi);
if S.R(1) < 1e-12, S.mu = NaN; end   % R1 = 0: середній напрям не визначений
S.V  = 1 - S.R(1);
if S.R(1) > 0
    S.sigma = sqrt(-2*log(min(S.R(1), 1)));
else
    S.sigma = Inf;
end
end
