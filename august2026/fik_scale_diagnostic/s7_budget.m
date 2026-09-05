function R = s7_budget(C, paths, U, IMG, budgetRows)
% S7_BUDGET  Крок 7 — бюджет масштабу + порівняння з моделлю july2026.
%   (1) зведена «сходинка» порядків величини по всій цепочці;
%   (2) прогін синтетичної моделі БТ (july2026) через ту саму формулу f_ik;
%   (3) що буде, якщо реальні поля НОРМУВАТИ до <I> = 1 (демонстрація причини).
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}}, 'data',struct());
kReal = budgetRows{end}.order;   % порядок |f_ik| на реальних даних (крок 6)

% ---- (1) сходинка порядків ------------------------------------------
stages = cellfun(@(b) b.stage, budgetRows, 'UniformOutput',false);
orders = cellfun(@(b) b.order, budgetRows);
fig = figure('Color','w','Visible','off','Position',[60 60 1000 460]);
ax = axes(fig);  bar(ax, orders, 'FaceColor',[0.35 0.5 0.75]);  grid(ax,'on');
set(ax,'XTick',1:numel(stages),'XTickLabel',stages,'FontName',C.fig.font, ...
       'FontSize',C.fig.fontSize,'XColor','k','YColor','k','TickLabelInterpreter','tex');
xtickangle(ax, 20);
ylabel(ax, 'порядок величини  (10^{k})', 'Color','k');
title(ax, 'Крок 7. Бюджет масштабу вздовж усієї цепочки', ...
      'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
for i = 1:numel(orders)
    text(ax, i, orders(i), sprintf(' 10^{%d}', orders(i)), 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'FontName',C.fig.font,'FontSize',C.fig.fontSize,'Interpreter','tex','Color','k');
end
R.figs{end+1} = U.save(fig, paths.steps, 7, 'magnitude_budget', C);

% ---- нормування реальних полів до <I> = 1 ---------------------------
statesR = {'in0','in45','in90','in135','inliv','inprav'};
sumI = 0;  cntI = 0;
for s = 1:numel(statesR)
    I = abs(IMG.(statesR{s}).Ex).^2 + abs(IMG.(statesR{s}).Ey).^2;
    sumI = sumI + sum(I(I>0));  cntI = cntI + nnz(I>0);
end
scaleR = sqrt(sumI / max(cntI,1));                 % RMS амплітуди поля
IMGn = IMG;
for p = fieldnames(IMGn).'
    IMGn.(p{1}).Ex = IMGn.(p{1}).Ex / scaleR;
    IMGn.(p{1}).Ey = IMGn.(p{1}).Ey / scaleR;
end
[A1n, A2n] = U.pair(IMGn, C.pairDir, C.pairDist);
Fn = tp_fik_pair(A1n, A2n);
gridFig(Fn, C, U, paths, 'real_normalized', ...
    sprintf('Крок 7. Реальні |f_{ik}| ПІСЛЯ нормування полів до <I>=1  (поділ на %s)', U.eng(scaleR)));
R.figs{end+1} = fullfile(paths.steps, '07.fik_grid.real_normalized.png');
kn = fgridOrder(Fn);
R.lines{end+1} = sprintf(['Якщо реальні поля поділити на їх RMS (%s), тобто привести <I> до 1, ' ...
    'то |f_{ik}| стають ~10^{%d} — тобто "малість" зникає повністю. Це прямий доказ, що ' ...
    'причина — МАСШТАБ полів, а не обчислення.'], U.eng(scaleR), kn);

% ---- (2) модель july2026 -------------------------------------------
if C.runModel
    try
        Fm = modelFik(C);
        gridFig(Fm, C, U, paths, 'model_july2026', ...
            'Крок 7. Модель july2026 (синтетична БТ): |f_{ik}| при нормованих інтенсивностях');
        R.figs{end+1} = fullfile(paths.steps, '07.fik_grid.model_july2026.png');
        km = fgridOrder(Fm);
        R.data.kModel = km;
        kfield = U.orderOf(scaleR);   % порядок масштабу сирого поля (RMS), ~ -3
        R.lines{end+1} = sprintf(['Синтетична модель july2026 (та сама формула f_{ik}, але ' ...
            'інтенсивності нормовані до [0,1] у tp_sim_speckle_BT) дає |f_{ik}| ~ 10^{%d}. ' ...
            'Різниця з реальними даними (~10^{%d}) — це рівно (масштаб поля)^2 ≈ (10^{%d})^2 = 10^{%d}.'], ...
            km, kReal, kfield, 2*kfield);
    catch ME
        R.lines{end+1} = sprintf('Модель july2026 не запустилась: %s', ME.message);
    end
end

R.data.scaleR = scaleR;
R.data.kField = U.orderOf(scaleR);
R.data.kReal  = kReal;
R.data.kNorm  = kn;
R.budget{end+1} = struct('stage','ВИСНОВОК', 'quantity','f_{ik} малі ЧЕРЕЗ масштаб полів', ...
    'order',kReal, 'note','нормування <I>=1 -> f_{ik} ~ O(1), як у моделі');
end

% ======================================================================
function Fm = modelFik(C)
% Прогін синтетичної моделі БТ (july2026) -> комплексні поля -> tp_fik_pair.
%   ВАЖЛИВО: july2026\core має однойменні tp_fik_pair/tp_slice (для BMP-формату).
%   Тому додаємо на шлях ЛИШЕ simulation\ і прибираємо його одразу після
%   виклику tp_sim_speckle_BT — щоб не затінити august2026\core.
simDir = fullfile(C.modelRoot,'simulation');
addpath(simDir);
cleaner = onCleanup(@() rmpath(simDir));
MCFG = struct();
MCFG.crop = struct('size', C.crop.size);
MCFG.sim  = struct('axisCorrLen',40, 'retCorrLen',30, 'speckleCorrLen',6, ...
                   'retMin',0, 'retMax',pi, 'seed',7);
[~, ~, DBGm] = tp_sim_speckle_BT(MCFG);      % DBGm.field.(P).Ex/Ey (комплексні)
% нормування полів моделі до <I> = 1 (щоб масштаб був "як має бути")
pols = {'in0','in45','in90','inRC'};
sumI = 0; cnt = 0;
for p = 1:numel(pols)
    E = DBGm.field.(pols{p});
    I = abs(E.Ex).^2 + abs(E.Ey).^2;  sumI = sumI + sum(I(:)); cnt = cnt + numel(I);
end
sc = sqrt(sumI/cnt);
IMGm = struct();
for p = 1:numel(pols)
    E = DBGm.field.(pols{p});
    IMGm.(pols{p}) = struct('Ex', E.Ex/sc, 'Ey', E.Ey/sc);
end
IMGm.in135  = IMGm.in90;   % моделі байдуже (тільки для сумісності структури)
IMGm.inliv  = IMGm.inRC;
IMGm.inprav = IMGm.inRC;
d = 8;  N = size(IMGm.in0.Ex,1);
A1 = struct(); A2 = struct();
for p = {'in0','in45','in90','inRC'}
    A1.(p{1}) = struct('Ex',IMGm.(p{1}).Ex(:,1:N-d),'Ey',IMGm.(p{1}).Ey(:,1:N-d));
    A2.(p{1}) = struct('Ex',IMGm.(p{1}).Ex(:,1+d:N),'Ey',IMGm.(p{1}).Ey(:,1+d:N));
end
Fm = tp_fik_pair(A1, A2);
end

% ======================================================================
function gridFig(F, C, U, paths, tag, ttl)
fig = figure('Color','w','Visible','off','Position',[40 40 1150 1120]);
allv = fgridVals(F, false);
for i=1:4
    for k=1:4
        ax = subplot(4,4,(i-1)*4+k);
        M = abs(F.(sprintf('f%d%d',i,k)));
        imagesc(ax, M);  axis(ax,'image');  set(ax,'YDir','normal','XTick',[],'YTick',[]);
        colormap(ax, C.fig.cmapMod);
        v = M(isfinite(M)); if ~isempty(v) && max(v)>min(v); clim(ax,[min(v) max(v)]); end
        title(ax, sprintf('|f_{%d%d}|', i,k), 'Interpreter','tex', ...
              'FontName',C.fig.font,'FontSize',C.fig.fontSize-1,'FontWeight','normal');
    end
end
sgtitle(sprintf('%s\nмедіанний |f_{ik}| ~ 10^{%d}', ttl, U.orderOf(allv)), ...
        'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
U.save(fig, paths.steps, 7, sprintf('fik_grid.%s', tag), C);
end

function k = fgridOrder(F)
allv = fgridVals(F, true);
if isempty(allv); k = NaN; else; k = round(log10(median(allv))); end
end

function v = fgridVals(F, posOnly)
v = [];
for i = 1:4
    for k = 1:4
        M = abs(F.(sprintf('f%d%d',i,k)));
        m = M(isfinite(M));
        if posOnly; m = m(m>0); end
        v = [v; m]; %#ok<AGROW>
    end
end
end
