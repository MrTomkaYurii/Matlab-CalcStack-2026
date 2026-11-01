function R = tp_algo_generalized_batch(IMG, CFG, sampleName, step)
% TP_ALGO_GENERALIZED_BATCH  Той самий узагальнений двоточковий скан, що й
%   tp_algo_generalized.m (ті самі формули tp_fik_pair, ті самі перші точки,
%   ті самі mod/arg/cplx на кожне рознесення), але зсуви рахуються ПАЧКАМИ
%   (векторно) — на GPU (RTX, gpuArray) або на CPU.
%
%   Як це влаштовано:
%     * поля Ex,Ey кожного освітлення доповнюються NaN-рамкою шириною mmax,
%       тож друга точка за межами кадру автоматично дає NaN-пару і
%       випадає з усереднення (omitnan) — як і в циклічній версії;
%     * перші точки — та сама проріджена сітка, що в tp_algo_generalized
%       (для від'ємних зсувів сітка зсунута так само);
%     * для стовпця Δx усі Δy рахуються пачками по CFG.gen.batchShifts:
%       матриця [перші точки x зсуви], формули (6)-(13) і розд. 4.
%
%   CFG.gen.useGPU      : true — рахувати на GPU (gpuArray, NVIDIA)
%   CFG.gen.precision   : 'single' (типово для GPU) | 'double'
%                         суми накопичуються в double в обох випадках
%   CFG.gen.batchShifts : скільки зсувів Δy за раз (типово 64)
%
%   R : канонічна структура результату (як у tp_algo_generalized).

if nargin < 4, step = CFG.gen.steps(1); end

N   = CFG.crop.size;
els = CFG.elements;  nE = numel(els);

posStep = CFG.gen.posStep;
if step == 1, posStep = max(posStep, 2); end   % те саме автоправило, що в циклічній версії
maxDist = CFG.gen.maxDist; if isempty(maxDist), maxDist = N-1; end
mmax = floor(maxDist/step) * step;
dxs = -mmax:step:mmax;  dys = dxs;
nx = numel(dxs); ny = numel(dys);
excludeZero = CFG.gen.excludeZero;

useGPU = isfield(CFG.gen,'useGPU') && CFG.gen.useGPU;
prec = 'double';
if isfield(CFG.gen,'precision') && ~isempty(CFG.gen.precision), prec = CFG.gen.precision;
elseif useGPU, prec = 'single';
end
B = 64; if isfield(CFG.gen,'batchShifts') && ~isempty(CFG.gen.batchShifts), B = CFG.gen.batchShifts; end

dir = sprintf('step_%d', step);
R = tp_base_result('generalized', sampleName, CFG);
R.dirs = {dir};
R.axes.(dir)  = struct('x',dxs,'y',dys);
R.label.(dir) = struct('x','\Delta x (px)','y','\Delta y (px)');

if useGPU
    dev = gpuDevice;
    fprintf('  [generalized-batch] %s: grid %dx%d, posStep=%d, GPU %s, %s, batch=%d ...\n', ...
            dir, nx, ny, posStep, dev.Name, prec, B);
else
    fprintf('  [generalized-batch] %s: grid %dx%d, posStep=%d, CPU, %s, batch=%d ...\n', ...
            dir, nx, ny, posStep, prec, B);
end

% ---- попередньо: |Ex|, |Ey|, delta кожного освітлення на доповненій сітці
pols = {'in0','in45','in90','inRC'};
Np = N + 2*mmax;                       % розмір доповненого кадру
P = struct();
for p = 1:numel(pols)
    S = IMG.(pols{p});
    ax_ = nan(Np, prec);  ay_ = nan(Np, prec);  dl_ = nan(Np, prec);
    ax_(mmax+(1:N), mmax+(1:N)) = cast(abs(S.Ex), prec);
    ay_(mmax+(1:N), mmax+(1:N)) = cast(abs(S.Ey), prec);
    dl_(mmax+(1:N), mmax+(1:N)) = cast(angle(S.Ey) - angle(S.Ex), prec);
    if useGPU, ax_ = gpuArray(ax_); ay_ = gpuArray(ay_); dl_ = gpuArray(dl_); end
    P.(pols{p}) = struct('Ex', ax_(:), 'Ey', ay_(:), 'd', dl_(:));
end

% ---- результат
MD = nan(ny, nx, nE);  AR = nan(ny, nx, nE);  CP = complex(nan(ny, nx, nE));

for ix = 1:nx
    dx = dxs(ix);
    if dx >= 0, c1 = 1:posStep:(N-dx); else, c1 = (1-dx):posStep:N; end
    if isempty(c1), continue; end
    colOff = dx * Np;                  % зсув лінійного індексу по стовпцях

    % Δy групуються за сіткою перших рядків: для dy>=0 рядки 1:posStep:..,
    % для dy<0 — (1-dy):posStep:.. (як у tp_algo_generalized)
    rowStart = ones(1, ny);
    rowStart(dys < 0) = 1 - dys(dys < 0);
    grp = mod(rowStart - 1, posStep);
    for g = unique(grp)
        idxG = find(grp == g);
        r1 = (1+g):posStep:N;
        [RR, CC] = ndgrid(r1 + mmax, c1 + mmax);
        L1 = (CC(:)-1)*Np + RR(:);                       % перші точки (лінійні індекси)
        % у циклічній версії рядки першої точки обмежені діапазоном, де друга
        % точка в кадрі; тут ці пари дають NaN через рамку — результат той самий
        if useGPU, L1 = gpuArray(L1); end
        Q1 = struct();
        for p = 1:numel(pols)
            Q1.(pols{p}) = struct('Ex', P.(pols{p}).Ex(L1), 'Ey', P.(pols{p}).Ey(L1), 'd', P.(pols{p}).d(L1));
        end

        for b0 = 1:B:numel(idxG)
            ib = idxG(b0:min(b0+B-1, numel(idxG)));
            dyb = dys(ib);
            off = colOff + dyb;                          % 1 x nb
            if useGPU, off = gpuArray(cast(off, 'double')); end
            L2 = L1 + off;                               % M x nb
            F = fik_batch(Q1, P, L2, pols);
            for e = 1:nE
                z = F.(els{e});                          % M x nb, complex
                ok  = isfinite(z);
                cnt = sum(ok, 1);
                z(~ok) = 0;
                az  = abs(z);
                th  = angle(z);
                sm  = sum(az, 1, 'double');
                ss  = sum(sin(th) .* ok, 1, 'double');
                sc  = sum(cos(th) .* ok, 1, 'double');
                sz  = sum(z, 1, 'double');
                md  = gather(sm ./ cnt);
                ar  = gather(atan2(ss ./ cnt, sc ./ cnt));
                cp  = gather(sz ./ cnt);
                MD(ib, ix, e) = md(:);
                AR(ib, ix, e) = ar(:);
                CP(ib, ix, e) = cp(:);
            end
        end
    end
end

if excludeZero
    i0 = find(dys == 0);  j0 = find(dxs == 0);
    MD(i0, j0, :) = NaN;  AR(i0, j0, :) = NaN;  CP(i0, j0, :) = complex(NaN);
end

for e = 1:nE
    R.data.(dir).(els{e}) = struct('mod', MD(:,:,e), 'arg', AR(:,:,e), 'cplx', CP(:,:,e));
end
R.params = struct('step',step,'posStep',posStep,'maxDist',maxDist,'parallel',false, ...
                  'engine','batch','useGPU',useGPU,'precision',prec,'batchShifts',B);
end

% ------------------------------------------------------------------------
function F = fik_batch(Q1, P, L2, pols)
% Формули (6)-(13) і розд. 4 tp_fik_pair.m для пачки пар:
% перша точка — вектор (M x 1), друга — матриця індексів L2 (M x nb).
a = cell(4,1);  b = cell(4,1);
for p = 1:numel(pols)
    S1 = Q1.(pols{p});
    Ex1 = S1.Ex;  Ey1 = S1.Ey;  d1 = S1.d;
    Ex2 = P.(pols{p}).Ex(L2);  Ey2 = P.(pols{p}).Ey(L2);  d2 = P.(pols{p}).d(L2);
    dd = d2 - d1;
    EE = Ex1 .* Ex2;  YY = Ey1 .* Ey2;
    c  = cos(dd);  s = sin(dd);
    X12 = Ex1 .* Ey2;  X21 = Ex2 .* Ey1;
    c2 = cos(d2);  s2 = sin(d2);  c1 = cos(d1);  s1 = sin(d1);
    a{1}.(pols{p}) =  EE + YY .* c;            b{1}.(pols{p}) =  YY .* s;
    a{2}.(pols{p}) =  EE - YY .* c;            b{2}.(pols{p}) = -YY .* s;
    a{3}.(pols{p}) =  X12 .* c2 + X21 .* c1;   b{3}.(pols{p}) =  X12 .* s2 - X21 .* s1;
    a{4}.(pols{p}) =  X12 .* s2 + X21 .* s1;   b{4}.(pols{p}) =  X12 .* c2 - X21 .* c1;
end
F = struct();
for i = 1:4
    Asum = a{i}.in0 + a{i}.in90;  Bsum = b{i}.in0 + b{i}.in90;
    F.(sprintf('f%d1',i)) = 0.5*complex(Asum,  Bsum);
    F.(sprintf('f%d2',i)) = 0.5*complex(Asum, -Bsum);
    F.(sprintf('f%d3',i)) = complex(a{i}.in45 - Asum, b{i}.in45 - Bsum);
    F.(sprintf('f%d4',i)) = complex(a{i}.inRC - Asum, b{i}.inRC - Bsum);
end
end
