function [IMG, SIM, DBG] = tp_sim_speckle_BT(CFG, example)
% TP_SIM_SPECKLE_BT  Фізична симуляція спекл-поля двопроменезаломної тканини (БТ).
%   ПЕРЕНЕСЕНО з july2026\simulation\tp_sim_speckle_BT.m. Фізика НЕ змінена:
%     * тканина = лінійний фазовий пластинчастий об'єкт із ПРОСТОРОВО ЗМІННИМИ
%       орієнтацією оптичної осі theta(x,y) та затримкою delta(x,y)
%       («архітектоніка» з власними напрямами осей і двопроменезаломленням);
%     * когерентне освітлення -> спекл через комплексний носій s(x,y);
%     * УСІ входи й аналізатори проходять через ОДИН джонсів оператор
%       J(theta,delta) -> зображення фізично зв'язані між собою.
%
%   АДАПТАЦІЯ під september2026 (нові дані = готові КОМПЛЕКСНІ Ex,Ey):
%     * замість 6 інтенсивностей (старий BMP-формат) повертаються самі
%       комплексні поля Ex,Ey, як їх віддає august2026_copy\tp_load_mat.m для реальних
%       зразків: IMG.(inPol).Ex / .Ey, inPol ∈ {in0,in45,in90,in135,inliv,
%       inprav} + псевдонім inRC = CFG.mat.rcSource ('liv'|'prav');
%     * освітлень 6 (було 4): 0, 45, 90, 135, ліве (liv) і праве (prav)
%       коло; праве = [1;-i]/sqrt(2) (те саме, що було "inRC" у july2026);
%     * НОРМУВАННЯ: один спільний множник на ВСІ 12 полів (крос-канальні
%       співвідношення зберігаються — як "СПІЛЬНЕ нормування" в оригіналі),
%       такий, що max|E| = CFG.sim.fieldScale (типово 1e-3 -- масштаб реальних
%       реконструйованих полів; 0 = без нормування). Величини Кроку B від
%       масштабу не залежать, але f_ik ~ 1e-6 як у реальних даних;
%     * приклад (example) -> реалізація: seed = CFG.sim.seed + 100*(example-1),
%       тож приклад '1' = точно оригінальна модель (seed 7), '2','3' -- інші
%       реалізації тієї ж тканини (не числовий example -> як '1');
%     * глобальний ГВЧ MATLAB зберігається/відновлюється (rng у smoothField/
%       speckleField більше не міняє стан викликача).
%
%   [IMG, SIM, DBG] = tp_sim_speckle_BT(CFG, example)
%     IMG : див. вище (комплексні Ex,Ey, N x N)
%     SIM : theta, delta, speckleAmp, specklePhase, seed, scale
%           (theta,delta -- ІСТИНА, за якою побудовано зразок)
%     DBG : DBG.field.(inPol) = struct('Ex','Ey') (ті самі, що в IMG),
%           DBG.pols (6 імен), DBG.J.J11..J22

if nargin < 2 || isempty(example), example = '1'; end
tp_assert(CFG.crop.size >= 2, 'tp_sim_speckle_BT: crop.size замалий (%d)', CFG.crop.size);
tp_assert(CFG.sim.axisCorrLen > 0 && CFG.sim.retCorrLen > 0 && CFG.sim.speckleCorrLen > 0, ...
    'tp_sim_speckle_BT: усі CFG.sim.*CorrLen мають бути > 0');
tp_assert(CFG.sim.retMax >= CFG.sim.retMin, 'tp_sim_speckle_BT: retMax < retMin');

N  = CFG.crop.size;
ei = str2double(example);  if ~isfinite(ei), ei = 1; end
sd = CFG.sim.seed + 100*(ei - 1);

rngState = rng;                         % не ламаємо глобальний ГВЧ викликача
cleaner  = onCleanup(@() rng(rngState)); %#ok<NASGU>

% --- архітектоніка тканини ------------------------------------------
theta = pi * smoothField(N, CFG.sim.axisCorrLen, sd);                 % орієнтація осі 0..pi
delta = CFG.sim.retMin + (CFG.sim.retMax - CFG.sim.retMin) * ...
        smoothField(N, CFG.sim.retCorrLen, sd+1);                     % затримка (двопром.)
s = speckleField(N, CFG.sim.speckleCorrLen, sd+2);                    % когерентний спекл-носій

% --- джонсів оператор лінійного ретардера (на піксель) --------------
c = cos(delta/2);  sn = sin(delta/2);  c2 = cos(2*theta);  s2 = sin(2*theta);
J11 = c + 1i*sn.*c2;   J12 = 1i*sn.*s2;
J21 = 1i*sn.*s2;       J22 = c - 1i*sn.*c2;

inNames = {'in0','in45','in90','in135','inliv','inprav'};
Ein     = { [1;0], [1;1]/sqrt(2), [0;1], [1;-1]/sqrt(2), [1;1i]/sqrt(2), [1;-1i]/sqrt(2) };

% --- поля на виході тканини (+ спекл) для всіх освітлень -------------
raw = struct();  gmax = 0;
for p = 1:numel(inNames)
    ax = Ein{p}(1);  ay = Ein{p}(2);
    Ex = s .* (J11*ax + J12*ay);
    Ey = s .* (J21*ax + J22*ay);
    raw.(inNames{p}) = struct('Ex', Ex, 'Ey', Ey);
    gmax = max([gmax, max(abs(Ex(:))), max(abs(Ey(:)))]);
end

% --- СПІЛЬНЕ нормування (один множник на всі поля) -------------------
scale = 1;
if isfield(CFG.sim,'fieldScale') && CFG.sim.fieldScale > 0
    scale = CFG.sim.fieldScale / (gmax + eps);
end
IMG = struct();
for p = 1:numel(inNames)
    IMG.(inNames{p}) = struct('Ex', raw.(inNames{p}).Ex * scale, ...
                              'Ey', raw.(inNames{p}).Ey * scale);
end
rcSrc = 'prav';
if isfield(CFG,'mat') && isfield(CFG.mat,'rcSource'), rcSrc = CFG.mat.rcSource; end
IMG.inRC = IMG.(['in' rcSrc]);          % так само, як tp_load_mat.m

SIM = struct('theta',theta, 'delta',delta, 'speckleAmp',abs(s), ...
             'specklePhase',angle(s), 'seed',sd, 'scale',scale);

if nargout > 2
    DBG.pols  = inNames;
    DBG.field = rmfield(IMG, 'inRC');
    DBG.J     = struct('J11',J11, 'J12',J12, 'J21',J21, 'J22',J22);
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
