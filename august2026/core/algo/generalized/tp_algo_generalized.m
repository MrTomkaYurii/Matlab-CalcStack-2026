function R = tp_algo_generalized(IMG, CFG, sampleName, step)
% TP_ALGO_GENERALIZED  Узагальнене двоточкове сканування (2D псевдо-АКФ), ОДИН крок.
%   Реалізує "Обобщённый_алгоритм_двухточечного_сканирования".
%   Рахує ОДНУ ρ-діаграму для заданого кроку `step` (крок сітки рознесень)
%   -> напрям (тека) 'step_<step>'. Оркестратор викликає це в циклі по
%   CFG.gen.steps: порахував крок -> зберіг -> намалював -> наступний крок.
%   Для кожного рознесення усереднюємо по всіх (проріджених) перших точках:
%     модуль — арифметично; аргумент — кругово atan2(sum sin, sum cos).
%   posStep — прорідження перших точок. Розпаралелено по стовпцях Δx.
%
%   R : канонічна структура результату (з одним напрямом), для tp_visualize.

if nargin < 4, step = CFG.gen.steps(1); end

N   = CFG.crop.size;
els = CFG.elements;  nE = numel(els);

posStep = CFG.gen.posStep;
if step == 1
    % крок 1 => найважчий випадок (найгустіша сітка рознесень); автоматично
    % піднімаємо прорідження щонайменше до 2 заради швидкості. Якщо користувач
    % сам задав більше (напр. 3) — це значення не занижується.
    posStep = max(posStep, 2);
end
maxDist = CFG.gen.maxDist; if isempty(maxDist), maxDist = N-1; end
mmax = floor(maxDist/step) * step;          % симетрична сітка, кратна кроку
dxs = -mmax:step:mmax;  dys = dxs;
nx = numel(dxs); ny = numel(dys);

excludeZero = CFG.gen.excludeZero;
useParallel = isfield(CFG.gen,'parallel') && CFG.gen.parallel;
M = 0; if useParallel, M = Inf; end   % M=0 -> послідовно; M=Inf -> усі ядра

dir = sprintf('step_%d', step);
R = tp_base_result('generalized', sampleName, CFG);
R.dirs = {dir};
R.axes.(dir)  = struct('x',dxs,'y',dys);
R.label.(dir) = struct('x','\Delta x (px)','y','\Delta y (px)');

fprintf('  [generalized] %s: grid %dx%d, posStep=%d, parallel=%d ...\n', ...
        dir, nx, ny, posStep, useParallel);

% один стовпець Δx на ітерацію parfor
colMod = cell(nx,1); colArg = cell(nx,1); colCpx = cell(nx,1);
parfor (ix = 1:nx, M)
    dx = dxs(ix);
    if dx >= 0, c1 = 1:posStep:(N-dx); else, c1 = (1-dx):posStep:N; end
    c2 = c1 + dx;

    md = nan(ny,nE); ar = nan(ny,nE); cp = complex(nan(ny,nE));
    if ~isempty(c1)
        for iy = 1:ny
            dy = dys(iy);
            if excludeZero && dx==0 && dy==0, continue; end
            if dy >= 0, r1 = 1:posStep:(N-dy); else, r1 = (1-dy):posStep:N; end
            r2 = r1 + dy;
            if isempty(r1), continue; end
            F = tp_fik_pair(tp_slice(IMG,r1,c1), tp_slice(IMG,r2,c2));
            for e = 1:nE
                z = F.(els{e})(:);
                md(iy,e) = mean(abs(z), 'omitnan');
                ar(iy,e) = atan2(mean(sin(atan2(imag(z), real(z))),'omitnan'), mean(cos(atan2(imag(z), real(z))),'omitnan'));
                cp(iy,e) = mean(z, 'omitnan');
            end
        end
    end
    colMod{ix} = md; colArg{ix} = ar; colCpx{ix} = cp;
end

% зібрати стовпці у 2D-карти (Δy рядки, Δx стовпці)
for e = 1:nE
    md = nan(ny,nx); ar = nan(ny,nx); cp = complex(nan(ny,nx));
    for ix = 1:nx
        md(:,ix) = colMod{ix}(:,e);
        ar(:,ix) = colArg{ix}(:,e);
        cp(:,ix) = colCpx{ix}(:,e);
    end
    R.data.(dir).(els{e}) = struct('mod',md,'arg',ar,'cplx',cp);
end

R.params = struct('step',step,'posStep',posStep,'maxDist',maxDist,'parallel',useParallel);
end
