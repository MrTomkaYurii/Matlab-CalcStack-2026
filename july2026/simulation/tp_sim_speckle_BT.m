function [IMG, SIM, DBG] = tp_sim_speckle_BT(CFG)
% TP_SIM_SPECKLE_BT  Фізична симуляція спекл-поля двопроменезаломної тканини (БТ).
%   Модель, наближена до реального світу:
%     * тканина = лінійний фазовий пластинчастий об'єкт із ПРОСТОРОВО ЗМІННИМИ
%       орієнтацією оптичної осі theta(x,y) та затримкою delta(x,y)
%       («архітектоніка» з власними напрямами осей і двопроменезаломленням);
%     * когерентне освітлення -> спекл через комплексний носій s(x,y);
%     * УСІ входи (0,45,90,RC) і аналізатори проходять через ОДИН джонсів
%       оператор J(theta,delta) -> зображення фізично зв'язані між собою;
%     * СПІЛЬНЕ нормування всіх каналів (важливо!) зберігає крос-канальні
%       співвідношення, потрібні для коректної матриці Мюллера.
%
%   IMG.(inPol).(analyzer) : N x N double у [0,1]
%   SIM : theta, delta, speckleAmp, specklePhase (для попереднього перегляду)

tp_assert(CFG.crop.size >= 2, 'tp_sim_speckle_BT: crop.size замалий (%d)', CFG.crop.size);
tp_assert(CFG.sim.axisCorrLen > 0 && CFG.sim.retCorrLen > 0 && CFG.sim.speckleCorrLen > 0, ...
    'tp_sim_speckle_BT: усі CFG.sim.*CorrLen мають бути > 0');
tp_assert(CFG.sim.retMax >= CFG.sim.retMin, 'tp_sim_speckle_BT: retMax < retMin');

N  = CFG.crop.size;
sd = CFG.sim.seed;

% --- архітектоніка тканини ------------------------------------------
theta = pi * smoothField(N, CFG.sim.axisCorrLen, sd);                 % орієнтація осі 0..pi
delta = CFG.sim.retMin + (CFG.sim.retMax - CFG.sim.retMin) * ...
        smoothField(N, CFG.sim.retCorrLen, sd+1);                     % затримка (двопром.)
s = speckleField(N, CFG.sim.speckleCorrLen, sd+2);                    % когерентний спекл-носій

% --- джонсів оператор лінійного ретардера (на піксель) --------------
c = cos(delta/2);  sn = sin(delta/2);  c2 = cos(2*theta);  s2 = sin(2*theta);
J11 = c + 1i*sn.*c2;   J12 = 1i*sn.*s2;
J21 = 1i*sn.*s2;       J22 = c - 1i*sn.*c2;

inPols = {'in0','in45','in90','inRC'};
Ein    = { [1;0], [1;1]/sqrt(2), [0;1], [1;-1i]/sqrt(2) };   % джонсові вектори входу

% --- обчислення інтенсивностей для всіх комбінацій ------------------
raw = struct();  gmax = 0;
for p = 1:numel(inPols)
    ax = Ein{p}(1);  ay = Ein{p}(2);
    Ex = s .* (J11*ax + J12*ay);       % поле на виході тканини + спекл
    Ey = s .* (J21*ax + J22*ay);

    S = struct();
    S.I0    = abs(Ex).^2;
    S.I90   = abs(Ey).^2;
    S.I45   = 0.5 * abs(Ex + Ey).^2;
    S.I135  = 0.5 * abs(Ex - Ey).^2;
    S.Iprav = 0.5 * abs(Ex - 1i*Ey).^2;   % права циркулярна
    S.Iliv  = 0.5 * abs(Ex + 1i*Ey).^2;   % ліва  циркулярна
    raw.(inPols{p}) = S;

    if nargout > 2   % проміжні поля для покрокового аналізу симуляції
        DBG.field.(inPols{p}) = struct('Ex',Ex,'Ey',Ey);
    end

    fn = fieldnames(S);
    for f = 1:numel(fn), gmax = max(gmax, max(S.(fn{f})(:))); end
end

% --- СПІЛЬНЕ нормування (один множник на всі канали й освітлення) ----
IMG = struct();
for p = 1:numel(inPols)
    S = raw.(inPols{p});  fn = fieldnames(S);
    for f = 1:numel(fn), S.(fn{f}) = S.(fn{f}) / (gmax + eps); end
    IMG.(inPols{p}) = S;
end

SIM = struct('theta',theta, 'delta',delta, 'speckleAmp',abs(s), ...
             'specklePhase',angle(s), 'gmax',gmax);

if nargout > 2
    DBG.pols = inPols;
    DBG.J = struct('J11',J11, 'J12',J12, 'J21',J21, 'J22',J22);
end
end

% ------------------------------------------------------------------------
function A = smoothField(N, L, seed)
% Гладке дійсне поле: низькочастотно відфільтрований гаусів шум, у [0,1].
rng(seed);
G = randn(N);
[u,v] = meshgrid(-floor(N/2):ceil(N/2)-1);
H = exp(-(u.^2 + v.^2) / (2*(N/(2*pi*max(L,1)))^2));
A = real(ifft2(ifftshift(fftshift(fft2(G)).*H)));
A = (A - min(A(:))) / (max(A(:)) - min(A(:)) + eps);
end

function s = speckleField(N, L, seed)
% Комплексний спекл-носій: НЧ-фільтрований комплексний білий шум.
rng(seed);
G = randn(N) + 1i*randn(N);
[u,v] = meshgrid(-floor(N/2):ceil(N/2)-1);
H = exp(-(u.^2 + v.^2) / (2*(N/(2*pi*max(L,1)))^2));
s = ifft2(ifftshift(fftshift(fft2(G)).*H));
end
