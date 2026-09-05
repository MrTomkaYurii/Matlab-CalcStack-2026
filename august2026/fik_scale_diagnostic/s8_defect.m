function R = s8_defect(C, paths, U)
% S8_DEFECT  Крок 8 — окремий (не про масштаб) дефект даних: порожні канали
%   ey_0 / ex_90 у частині зразків (Серце/1, усі приклади Мозг). Наслідок:
%   4 елементи матриці (f31,f32,f41,f42) виходять ТОТОЖНО нульовими.
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

[IMG, meta] = U.loadFields(C.matRoot, C.defectSample, C.defectExample, C.crop, C.rcSource);

fig = figure('Color','w','Visible','off','Position',[50 50 1100 780]);
U.panel(subplot(2,3,1), abs(IMG.in0.Ex),  '|Ex| @ 0°  (норм.)',        C.fig.cmapMod, C);
U.panel(subplot(2,3,2), abs(IMG.in0.Ey),  '|Ey| @ 0°  — ПОРОЖНІЙ',     C.fig.cmapMod, C);
U.hist (subplot(2,3,3), abs(IMG.in0.Ey),  '|Ey| @ 0°  розподіл',       C);
U.panel(subplot(2,3,4), abs(IMG.in90.Ex), '|Ex| @ 90° — ПОРОЖНІЙ',     C.fig.cmapMod, C);
U.panel(subplot(2,3,5), abs(IMG.in90.Ey), '|Ey| @ 90°  (норм.)',       C.fig.cmapMod, C);
U.hist (subplot(2,3,6), abs(IMG.in90.Ex), '|Ex| @ 90°  розподіл',      C);
sgtitle(sprintf(['Крок 8. Дефект даних (%s / %s): порожні канали %s\n' ...
    '(сира голограма цих кадрів не мала інтерференційних смуг -> реконструкція дала нулі)'], ...
    C.defectSample, C.defectExample, strjoin(meta.zero, ', ')), ...
    'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','none','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 8, 'defect.zero_channels', C);

% наслідок для f_ik
[A1, A2] = U.pair(IMG, C.pairDir, C.pairDist);
F = tp_fik_pair(A1, A2);
fig = figure('Color','w','Visible','off','Position',[40 40 1150 1120]);
zeroEls = {};
for i=1:4
    for k=1:4
        ax = subplot(4,4,(i-1)*4+k);
        M = abs(F.(sprintf('f%d%d',i,k)));
        imagesc(ax, M);  axis(ax,'image');  set(ax,'YDir','normal','XTick',[],'YTick',[]);
        colormap(ax, C.fig.cmapMod);
        v = M(isfinite(M)); if ~isempty(v) && max(v)>min(v); clim(ax,[min(v) max(v)]); end
        isZ = max(M(:))==0;
        if isZ; zeroEls{end+1} = sprintf('f%d%d',i,k); end %#ok<AGROW>
        title(ax, sprintf('|f_{%d%d}|%s', i,k, ternS(isZ,'  ≡ 0','')), 'Interpreter','tex', ...
              'FontName',C.fig.font,'FontSize',C.fig.fontSize-1,'FontWeight','normal', ...
              'Color', ternC(isZ,[0.75 0 0],[0 0 0]));
    end
end
sgtitle(sprintf(['Крок 8. Наслідок: тотожно нульові елементи  %s\n' ...
    '(a_3,a_4 для 0° і 90° = 0  ->  A_{sum}=B_{sum}=0  ->  f_{31},f_{32},f_{41},f_{42}=0)'], ...
    strjoin(zeroEls, ', ')), 'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 8, 'defect.fik_zeros', C);

R.lines{end+1} = sprintf(['ОКРЕМА проблема (не масштаб): у %s/%s канали %s — суцільні нулі ' ...
    '(немає інтерференційних смуг у сирій голограмі). Через це проміжні a_3,a_4 для ' ...
    'освітлень 0° і 90° занулюються, A_{sum}=B_{sum}=0, і елементи %s виходять ТОТОЖНО ' ...
    'нульовими. Це впливає на %s/1 та всі приклади Мозг; Серце/2,3 — чисті.'], ...
    C.defectSample, C.defectExample, strjoin(meta.zero, ', '), strjoin(zeroEls, ', '), C.defectSample);
end

function s = ternS(c,a,b); if c; s=a; else; s=b; end; end
function v = ternC(c,a,b); if c; v=a; else; v=b; end; end
