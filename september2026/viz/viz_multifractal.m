function viz_multifractal(D, meta, ctx, CFG)
% VIZ_MULTIFRACTAL  Мультифрактальний спектр (WTMM, tp_multifractal.m) —
%   ОДНА фігура, усе потрібне з мультифрактального аналізу разом:
%     ряд 1: партиційні функції log Z(q,a) vs log(a) + лінії апроксимації,
%            кілька q                                                    (модуль | аргумент)
%     ряд 2: масовий показник tau(q), з R^2 апроксимації (якість степеневого
%            закону — без цього неможливо перевірити, чи спектр взагалі валідний)
%     ряд 3: показник Гельдера h(q)                                      (модуль | аргумент)
%     ряд 4: спектр f(h) — головний результат, з підписаною шириною Δh   (модуль | аргумент)
%   Це попередній огляд ДЛЯ НАС: повний мультифрактальний аналіз (з
%   ланцюжковим WTMM-трекінгом ліній) робить М.Горський на сирих
%   розподілах, які ми йому передаємо (run_TwoPoint_CollectForHorsky).

% Лінійні графіки (без imagesc/colormap) -> НЕ циклюємо по CFG.viz.colormaps
% (jet/gray тут візуально нічого не міняють, лише даремно подвоюють
% exportgraphics — найдорожчу частину рендерингу).
if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end
MFmod = tp_multifractal(D.mod, meta, CFG);
MFarg = tp_multifractal(D.arg, meta, CFG);

fig = figure('Color','w','Visible','off','Position',[60 20 1200 1650]);
S.light(fig);

renderColumn(MFmod, meta.modLabel, S, 1);
renderColumn(MFarg, meta.argLabel, S, 2);

sgtitle(sprintf('%s  \\cdot  multifractal spectrum (WTMM)', meta.titlePrefix), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('_block4_spectrum_%s', ctx.name));
end

% ------------------------------------------------------------------------
function renderColumn(MF, qLabel, S, col)
axZ = subplot(4,2,col);
axT = subplot(4,2,2+col);
axH = subplot(4,2,4+col);
axF = subplot(4,2,6+col);

if MF.degenerate
    title(axZ, sprintf('(degenerate — %s)', qLabel));
    axis(axT,'off'); axis(axH,'off'); axis(axF,'off');
    return;
end

% ряд 1 — партиційні функції, кілька репрезентативних q (не всі — забагато ліній),
% З ЛІНІЄЮ АПРОКСИМАЦІЇ (пунктир) — щоб візуально бачити, чи справді
% степенева залежність (лінійна в log-log), а не просто вірити числу tau(q)
qShow = pickRepresentativeQ(MF.q);
cols = turbo(numel(qShow));
hold(axZ,'on');
logA = log(MF.a(:)');
for j = 1:numel(qShow)
    qi = find(MF.q == qShow(j), 1);
    if isempty(qi), continue; end
    valid = isfinite(MF.logZ(qi,:));
    plot(axZ, logA(valid), MF.logZ(qi,valid), 'o', 'Color',cols(j,:), ...
         'MarkerSize',3, 'DisplayName',sprintf('q=%.1f', qShow(j)));
    if isfinite(MF.tau(qi))
        yFit = MF.tau(qi)*logA(valid) + MF.tauIntercept(qi);
        plot(axZ, logA(valid), yFit, ':', 'Color',cols(j,:), 'LineWidth',1.2, 'HandleVisibility','off');
    end
end
xlabel(axZ,'log(a)','FontSize',S.labelSize); ylabel(axZ,'log Z(q,a)','FontSize',S.labelSize);
title(axZ, sprintf('Partition function (dots) + fit (dashed) — %s', qLabel), ...
      'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
legend(axZ,'Location','eastoutside','FontSize',7); S.apply(axZ);

% ряд 2 — масовий показник tau(q), з якістю апроксимації R^2
plot(axT, MF.q, MF.tau, 'o-', 'Color',[0.20 0.40 0.80], 'MarkerFaceColor',[0.20 0.40 0.80], ...
     'MarkerSize',4, 'LineWidth',1.4);
xlabel(axT,'q','FontSize',S.labelSize); ylabel(axT,'\tau(q)','FontSize',S.labelSize,'Interpreter','tex');
title(axT, sprintf('Mass exponent \\tau(q) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
r2v = MF.R2(isfinite(MF.R2));
if ~isempty(r2v)
    text(axT, 0.03,0.05, sprintf('R^2: mean=%.3f, min=%.3f', mean(r2v), min(r2v)), ...
         'Units','normalized','VerticalAlignment','bottom','FontName','Consolas','FontSize',8, ...
         'Color',S.ink,'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',2);
end
S.apply(axT);

% ряд 3 — показник Гельдера h(q)
plot(axH, MF.q, MF.h, 'o-', 'Color',[0.15 0.55 0.35], 'MarkerFaceColor',[0.15 0.55 0.35], ...
     'MarkerSize',4, 'LineWidth',1.4);
xlabel(axH,'q','FontSize',S.labelSize); ylabel(axH,'h(q) = d\tau/dq','FontSize',S.labelSize,'Interpreter','tex');
title(axH, sprintf('Holder exponent h(q) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(axH);

% ряд 4 — сам спектр f(h), головний результат
valid = isfinite(MF.h) & isfinite(MF.f);
plot(axF, MF.h(valid), MF.f(valid), 'o-', 'Color',[0.80 0.20 0.20], 'MarkerFaceColor',[0.80 0.20 0.20], ...
     'MarkerSize',4, 'LineWidth',1.6);
xlabel(axF,'h  (Holder exponent)','FontSize',S.labelSize);
ylabel(axF,'f(h)','FontSize',S.labelSize);
title(axF, sprintf('Multifractal spectrum f(h) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
text(axF, 0.03,0.95, sprintf('\\Delta h = %.3f', MF.deltaH), 'Units','normalized', ...
     'VerticalAlignment','top','FontName','Consolas','FontSize',10,'FontWeight','bold', ...
     'Color',S.ink,'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3,'Interpreter','tex');
S.apply(axF);
end

% ------------------------------------------------------------------------
function qShow = pickRepresentativeQ(qAll)
% До 5 репрезентативних q (мін, макс, 0, і дві проміжні), щоб не малювати
% всі 20+ ліній партиційної функції одна на одній.
if numel(qAll) <= 5
    qShow = qAll; return;
end
lo = min(qAll); hi = max(qAll);
targets = [lo, lo/2, 0, hi/2, hi];
qShow = zeros(size(targets));
for i = 1:numel(targets)
    [~,idx] = min(abs(qAll - targets(i)));
    qShow(i) = qAll(idx);
end
qShow = unique(qShow, 'stable');
end
