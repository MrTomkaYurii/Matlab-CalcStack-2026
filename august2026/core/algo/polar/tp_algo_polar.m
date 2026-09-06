function R = tp_algo_polar(IMG, CFG, sampleName)
% TP_ALGO_POLAR  Полярне двоточкове сканування з ЄДИНОЮ картою.
%   Для КОЖНОЇ першої точки r1 друга точка r2 сканується по КОЛУ навколо неї:
%   кути theta = 0 : angleStep : angleMax-angleStep (град), радіус rho з
%   CFG.polar.radii (px). Усі напрями зводяться в ОДНУ карту PERP КОМПЛЕКСНОЮ
%   СУМОЮ (БЕЗ ділення на кількість — «об'єднання без усереднення»):
%       f_perp(r1) = SUM_theta  f_ik( r1, r1 + rho*(cos theta, sin theta) )
%   Комплексне складання — ДО модуля/аргумента (як у документі
%   «...с единой картой», розд.7). Точка 2 за межами кадру / у NaN фазового
%   вікна -> цей напрям НЕ входить у суму для того пікселя (розд.3 документа).
%
%   Крім PERP зберігаються осьові карти OX (theta=0) та OY (theta=90 град) —
%   для оцінки орієнтаційної анізотропії (розд.8 документа).
%
%   Проміжні по-кутові карти |f_ik(theta)| + сума виводяться ОДНИМ рисунком
%   (subplot) для елементів CFG.polar.montageElements.
%
%   Кут theta відлічується від осі +x (як у документі): theta=0 -> +x -> OX;
%   theta=90 град -> +y -> OY.
%
%   IMG : IMG.(inPol).Ex/.Ey (комплексні N x N), inPol у {in0,in45,in90,in135,
%         inliv,inprav,inRC}. Може бути фазово-замаскованим (NaN поза вікном).
%   R   : канонічна структура результату (tp_base_result) для tp_visualize.

N   = CFG.crop.size;
els = CFG.elements;  nE = numel(els);
P   = CFG.polar;

posStep  = 1;  if isfield(P,'posStep'), posStep = P.posStep; end
thetaDeg = 0 : P.angleStep : (P.angleMax - P.angleStep);
theta    = thetaDeg * pi/180;
nT       = numel(theta);

rcSrc = 'prav';
if isfield(CFG,'mat') && isfield(CFG.mat,'rcSource'), rcSrc = CFG.mat.rcSource; end
pols  = {'in0','in45','in90','inRC'};                 % що потребує tp_fik_pair
src   = {'in0','in45','in90', ['in' rcSrc]};          % звідки брати в IMG

% --- сітка перших точок (прорідження posStep по обох осях) --------------
rr = 1:posStep:N;  cc = 1:posStep:N;
[C1, R1] = meshgrid(cc, rr);                          % цілочисельні координати точки 1
sz = size(C1);
full = (numel(rr) == N && numel(cc) == N);

% --- точка 1 (на сітці) — не залежить від кута/радіуса -----------------
A1 = struct();
for p = 1:4
    A1.(pols{p}) = struct('Ex', IMG.(src{p}).Ex(rr,cc), 'Ey', IMG.(src{p}).Ey(rr,cc));
end

R = tp_base_result('polar', sampleName, CFG);
R.dirs = {};

doMontage = ~isfield(P,'montage') || P.montage;
mEls = {};
if doMontage && isfield(P,'montageElements')
    mEls = intersect(P.montageElements, els, 'stable');
end

fprintf('  [polar] %s: %d кутів (0..%g град, крок %g), rho = %s, posStep=%d\n', ...
        sampleName, nT, P.angleMax, P.angleStep, mat2str(P.radii), posStep);

for si = 1:numel(P.radii)
    rho = P.radii(si);
    if rho >= N, continue; end

    Sacc = cell(1,nE);  for e = 1:nE, Sacc{e} = complex(zeros(sz)); end
    Ncnt = zeros(sz);
    Fox = [];  Foy = [];
    montage = cell(1,numel(mEls));
    for m = 1:numel(mEls), montage{m} = nan([sz nT], 'single'); end

    % --- цикл по кутах (швидко — interp2 + tp_fik_pair, ~< 1 c на rho) ---
    for t = 1:nT
        th = theta(t);
        c2 = C1 + rho*cos(th);
        r2 = R1 + rho*sin(th);

        A2 = struct();
        for p = 1:4
            Ex2 = interp2(IMG.(src{p}).Ex, c2, r2, 'linear', NaN);
            Ey2 = interp2(IMG.(src{p}).Ey, c2, r2, 'linear', NaN);
            A2.(pols{p}) = struct('Ex', Ex2, 'Ey', Ey2);
        end
        F = tp_fik_pair(A1, A2);

        Ncnt = Ncnt + isfinite(F.(els{1}));
        for e = 1:nE
            z  = F.(els{e});
            ok = isfinite(z);
            Sacc{e}(ok) = Sacc{e}(ok) + z(ok);       % КОМПЛЕКСНА СУМА, без /N
        end
        for m = 1:numel(mEls), montage{m}(:,:,t) = single(abs(F.(mEls{m}))); end
        if thetaDeg(t) == 0,  Fox = F; end
        if thetaDeg(t) == 90, Foy = F; end
    end

    % пікселі, де ЖОДЕН напрям не був валідним -> сума не визначена (NaN, не 0)
    noneValid = (Ncnt == 0);
    for e = 1:nE, Sacc{e}(noneValid) = complex(NaN); end

    % --- записати напрями у R ------------------------------------------
    dP = sprintf('PERP_step_%d', rho);
    for e = 1:nE, R.data.(dP).(els{e}) = packE(Sacc{e}, rr, cc, N, full); end
    R = addDir(R, dP, N, rho, 'PERP');

    Nfull = nan(N);  Nfull(rr,cc) = Ncnt;
    R.params.validCount.(dP) = Nfull;                 % скільки напрямів у сумі (край < nT)

    if ~isempty(Fox)
        d = sprintf('OX_step_%d', rho);
        for e = 1:nE, R.data.(d).(els{e}) = packE(Fox.(els{e}), rr, cc, N, full); end
        R = addDir(R, d, N, rho, 'OX');
    end
    if ~isempty(Foy)
        d = sprintf('OY_step_%d', rho);
        for e = 1:nE, R.data.(d).(els{e}) = packE(Foy.(els{e}), rr, cc, N, full); end
        R = addDir(R, d, N, rho, 'OY');
    end

    % --- рисунок по-кутових карт (subplot) ---------------------------
    for m = 1:numel(mEls)
        try
            polarMontage(montage{m}, abs(Sacc{m}), thetaDeg, mEls{m}, rho, sampleName, CFG);
        catch ME
            fprintf(2, '   [viz fail] polar montage %s/step_%d: %s\n', mEls{m}, rho, ME.message);
        end
    end
end

R.params.radii        = P.radii;
R.params.angleStepDeg = P.angleStep;
R.params.angleMaxDeg  = P.angleMax;
R.params.nAngles      = nT;
R.params.posStep      = posStep;
R.params.combine      = 'complex-sum';               % Sum_theta f, без ділення
end

% ======================================================================
function s = packE(z, rr, cc, N, full)
if full
    E = z;
else
    E = complex(nan(N));  E(rr,cc) = z;
end
s = struct('cplx', E, 'mod', abs(E), 'arg', angle(E));
end

function R = addDir(R, dir, N, rho, base)
R.axes.(dir)  = struct('x', 1:N, 'y', 1:N);
R.label.(dir) = struct('x', 'x (px)', 'y', 'y (px)');
R.sep.(dir)   = struct('direction', base, 'delta', rho);   % -> теки <base>\step_<rho>
R.dirs{end+1} = dir;
end

% ======================================================================
function polarMontage(stack, perpAbs, thetaDeg, elem, rho, sample, CFG)
% Одна фігура: |f_ik(theta)| для всіх кутів + остання клітинка — |Sum_theta f|.
%   Панелі даунсемпляться до <=160 px (для швидкого рендеру великих карт).
nT   = numel(thetaDeg);
nCol = ceil(sqrt(nT + 1));
nRow = ceil((nT + 1) / nCol);
ds   = @(A) A(round(linspace(1, size(A,1), min(160,size(A,1)))), ...
              round(linspace(1, size(A,2), min(160,size(A,2)))));

fig = figure('Color','w', 'Visible','off', ...
    'Position',[50 50 min(1500, 170*nCol) min(1200, 170*nRow)]);
try
    theme(fig, 'light');          % не давати MATLAB тёмну тему у -batch
catch
end
ink = [0 0 0];

av = stack(isfinite(stack));
cl = [0, prctile(av, 99)];  if ~(cl(2) > cl(1)), cl = [0 1]; end

for t = 1:nT
    ax = subplot(nRow, nCol, t);
    imagesc(ax, ds(stack(:,:,t)));  axis(ax, 'image', 'off');  clim(ax, cl);
    colormap(ax, 'jet');
    title(ax, sprintf('%g%s', thetaDeg(t), char(176)), 'FontSize', 8, 'Color', ink);
end

ax = subplot(nRow, nCol, nT + 1);
imagesc(ax, ds(perpAbs));  axis(ax, 'image', 'off');
pv = perpAbs(isfinite(perpAbs));
if ~isempty(pv) && max(pv) > min(pv), clim(ax, [min(pv) prctile(pv,99)]); end
colormap(ax, 'jet');
title(ax, '|\Sigma_\theta f|', 'FontSize', 8, 'Interpreter','tex', 'FontWeight','bold', 'Color', ink);

elemTeX = sprintf('f_{%s%s}', elem(2), elem(3));
sgtitle(sprintf('%s  \\cdot  polar  \\cdot  \\Delta = %d px  \\cdot  |%s(\\theta)|  +  \\Sigma_\\theta', ...
    strrep(strrep(sample,'\',' / '),'/',' / '), rho, elemTeX), ...
    'Interpreter','tex', 'FontWeight','bold', 'Color', ink);

tp_save_figure(fig, CFG, {sample, 'polar', 'PERP', sprintf('step_%d', rho), 'angle_montage'}, elem);
end
