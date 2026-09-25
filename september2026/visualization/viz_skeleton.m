function viz_skeleton(D, meta, ctx, CFG)
% VIZ_SKELETON  Подання (5) за ескізом: вейвлет-скелетон + гістограма максимумів.
%   Скелетон = лінії локальних максимумів |W(a,b)| (WTMM) у площині (b, a).
%   Гістограма F(h) = розподіл значень цих максимумів (модулів амплітуд
%   вейвлет-коефіцієнтів). Робиться для модуля й аргументу f_ik.
%   Будується у кожній colormap зі списку CFG.viz.colormaps (jet, gray).
%   Панелі: [ Sup(|f|) скелетон | F(h) |f| ; Sup(Arg) скелетон | F(h) Arg ].
%   Потребує Wavelet Toolbox (cwtfilterbank / wt).

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end

% CWT і WTMM-скелетон НЕ залежать від colormap — рахуємо ОДИН раз
% для модуля й аргументу, а не на кожен colormap.
compMod = tp_skeleton_comp(D.mod, meta, CFG);
compArg = tp_skeleton_comp(D.arg, meta, CFG);

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[60 60 1300 950]);
    S.light(fig);

    renderSkeletonPair(subplot(2,2,1), subplot(2,2,2), compMod, meta.modLabel, CFG, S, cmap);
    renderSkeletonPair(subplot(2,2,3), subplot(2,2,4), compArg, meta.argLabel, CFG, S, cmap);

    sgtitle(sprintf('%s  \\cdot  wavelet skeleton + F(h) of maxima  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('_block2_%s_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function renderSkeletonPair(axSkel, axHist, comp, qLabel, CFG, S, cmap)
if comp.degenerate
    title(axSkel,'(degenerate profile)'); return;
end
Bpts = comp.Bpts; Apts = comp.Apts; Hpts = comp.Hpts;

% ліва панель — скелетон у площині (b, a), колір = амплітуда максимуму
scatter(axSkel, Bpts, Apts, 10, Hpts, 'filled');
set(axSkel,'YScale','log'); colormap(axSkel, cmap);
cb = colorbar(axSkel); cb.Label.String='|W| at maxima'; cb.Color=S.ink;
xlabel(axSkel,'Translation b (px)','FontSize',S.labelSize); ylabel(axSkel,'Scale a','FontSize',S.labelSize);
title(axSkel, sprintf('Skeleton (WTMM) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(axSkel);

% права панель — гістограма F(h) розподілу максимумів
histogram(axHist, Hpts, CFG.viz.histBins, 'FaceColor',[0.30 0.55 0.35], 'EdgeColor',[0.2 0.2 0.2]);
xlabel(axHist,'h = |W| at maxima','FontSize',S.labelSize); ylabel(axHist,'F(h)  (count)','FontSize',S.labelSize);
title(axHist, sprintf('Distribution of maxima — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
if ~isempty(Hpts)
    text(axHist, 0.97,0.97, sprintf('N_{max} = %d\nmean = %.3g\nstd  = %.3g', numel(Hpts), mean(Hpts), std(Hpts)), ...
        'Units','normalized','VerticalAlignment','top','HorizontalAlignment','right', ...
        'FontName','Consolas','FontSize',9,'Color',S.ink,'BackgroundColor','w', ...
        'EdgeColor',[0.6 0.6 0.6],'Margin',3);
end
S.apply(axHist);
end
