function viz_multifractal_dimensions(D, meta, ctx, CFG)
% VIZ_MULTIFRACTAL_DIMENSIONS  Поглиблений набір до Блоку 4 (tp_multifractal.m):
%     ряд 1: узагальнені розмірності D(q) = tau(q)/(q-1), з позначеними
%            D0 (розмірність носія), D1 (інформаційна), D2 (кореляційна)
%     ряд 2: f(h) ще раз, але з позначеною лівою/правою півшириною й
%            анотацією асиметрії спектру (діагностична ознака)
%   Модуль | аргумент, по колонках.

% Лінійні графіки (без imagesc/colormap) -> НЕ циклюємо по CFG.viz.colormaps
% (те саме міркування, що й у viz_multifractal.m — не подвоюємо exportgraphics
% заради двох однакових картинок).
S = viz_style();
MFmod = tp_multifractal(D.mod, meta, CFG);
MFarg = tp_multifractal(D.arg, meta, CFG);

fig = figure('Color','w','Visible','off','Position',[60 40 1200 950]);
S.light(fig);

renderColumn(subplot(2,2,1), subplot(2,2,3), MFmod, meta.modLabel, S);
renderColumn(subplot(2,2,2), subplot(2,2,4), MFarg, meta.argLabel, S);

sgtitle(sprintf('%s  \\cdot  generalized dimensions D(q) + spectrum asymmetry', meta.titlePrefix), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('_block5_dimensions_%s', ctx.name));
end

% ------------------------------------------------------------------------
function renderColumn(axD, axF, MF, qLabel, S)
if MF.degenerate
    title(axD, sprintf('(degenerate — %s)', qLabel)); axis(axF,'off'); return;
end

% ряд 1 — D(q)
plot(axD, MF.q, MF.D, 'o-', 'Color',[0.30 0.30 0.30], 'MarkerSize',3, 'LineWidth',1.3);
hold(axD,'on');
markPoint(axD, 0, MF.D0, S.lineRed,  sprintf('D_0=%.3f',MF.D0));
markPoint(axD, 1, MF.D1, [0.15 0.65 0.30], sprintf('D_1=%.3f',MF.D1));
markPoint(axD, 2, MF.D2, S.lineBlue, sprintf('D_2=%.3f',MF.D2));
xlabel(axD,'q','FontSize',S.labelSize); ylabel(axD,'D(q)','FontSize',S.labelSize);
title(axD, sprintf('Generalized dimensions — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
% валідність: для СПРАВЖНЬОГО мультифрактала D(q) має НЕ ЗРОСТАТИ з q;
% порушення монотонності -> шумна/ненадійна апроксимація, а не фізика
dv = MF.D(isfinite(MF.D));
isMono = all(diff(dv) <= 1e-6);
if isMono
    monoTxt = 'monotonic (OK)'; monoCol = [0.15 0.55 0.15];
else
    monoTxt = 'NOT monotonic (check fit)'; monoCol = [0.75 0.15 0.15];
end
text(axD, 0.97,0.95, monoTxt, 'Units','normalized','VerticalAlignment','top', ...
     'HorizontalAlignment','right','FontSize',8,'FontWeight','bold','Color',monoCol, ...
     'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',2);
S.apply(axD);

% ряд 2 — f(h) з лівою/правою півшириною й асиметрією
valid = isfinite(MF.h) & isfinite(MF.f);
plot(axF, MF.h(valid), MF.f(valid), 'o-', 'Color',[0.80 0.20 0.20], 'MarkerSize',3, 'LineWidth',1.4);
hold(axF,'on');
[~,i0] = min(abs(MF.q));
xline(axF, MF.h0, ':', 'Color',[0.3 0.3 0.3], 'LineWidth',1, 'HandleVisibility','off');
plot(axF, MF.h0, MF.f(i0), 'k^', 'MarkerFaceColor','k', 'MarkerSize',6, 'HandleVisibility','off');
xlabel(axF,'h','FontSize',S.labelSize); ylabel(axF,'f(h)','FontSize',S.labelSize);
title(axF, sprintf('Spectrum asymmetry — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
txt = sprintf(['\\Delta h = %.3f\nleft (q>0)  = %.3f\nright (q<0) = %.3f\n' ...
               'asymmetry   = %+.3f'], MF.deltaH, MF.leftWidth, MF.rightWidth, MF.asymmetry);
text(axF, 0.97,0.05, txt, 'Units','normalized','VerticalAlignment','bottom','HorizontalAlignment','right', ...
     'FontName','Consolas','FontSize',8,'Color',S.ink,'BackgroundColor','w', ...
     'EdgeColor',[0.6 0.6 0.6],'Margin',3);
S.apply(axF);
end

% ------------------------------------------------------------------------
function markPoint(ax, qv, Dv, color, label)
if ~isfinite(Dv), return; end
plot(ax, qv, Dv, 'o', 'Color',color, 'MarkerFaceColor',color, 'MarkerSize',7, 'HandleVisibility','off');
text(ax, qv, Dv, ['  ' label], 'Color',color, 'FontSize',9, 'FontWeight','bold', ...
     'VerticalAlignment','bottom', 'Interpreter','tex');
end
