function viz_maps_hist(D, meta, ctx, CFG)
% VIZ_MAPS_HIST  Подання (1) за ескізом: 2x2 карти + гістограми.
%   Панелі: [ |f| карта | Arg карта ; гістограма |f| | гістограма Arg ].
%   По одній фігурі на кожну colormap зі списку CFG.viz.colormaps.
%   Стиль — за old/calc_2025_vis_DvotMM (Частина 02).

S = viz_style();

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 950]);
    S.light(fig);

    % (1) карта модуля
    ax = subplot(2,2,1);
    mapPanel(ax, meta.x, meta.y, D.mod, cmap, meta, meta.modLabel, ...
             sprintf('Module  %s', meta.modLabel), false);

    % (2) карта аргументу
    ax = subplot(2,2,2);
    mapPanel(ax, meta.x, meta.y, D.arg, cmap, meta, meta.argLabel, ...
             sprintf('Argument  %s', meta.argLabel), true);

    % (3) гістограма модуля
    ax = subplot(2,2,3);
    histPanel(ax, D.mod, meta.modLabel, false, CFG.viz.histBins, [0.20 0.40 0.80], S);
    title(ax, 'Histogram of module', 'FontSize',S.subSize,'FontWeight','bold');

    % (4) гістограма аргументу
    ax = subplot(2,2,4);
    histPanel(ax, D.arg, meta.argLabel, true,  CFG.viz.histBins, [0.80 0.40 0.20], S);
    title(ax, 'Histogram of argument', 'FontSize',S.subSize,'FontWeight','bold');

    sgtitle(sprintf('%s  \\cdot  maps & histograms  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);

    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_maps_hist_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function mapPanel(ax, x, y, Z, cmap, meta, cbLabel, ttl, isPhase)
im = imagesc(ax, x, y, Z); set(im,'AlphaData',isfinite(Z));
set(ax,'YDir','normal'); axis(ax,'image');
if isPhase
    colormap(ax, viz_arg_cmap(cmap)); caxis(ax, [0 2*pi]);
else
    colormap(ax, cmap);
    lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
    if isfinite(lo) && isfinite(hi) && lo<hi, caxis(ax,[lo hi]); end
end
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = [0.12 0.12 0.12];
xlabel(ax, meta.xlabel,'FontSize',11); ylabel(ax, meta.ylabel,'FontSize',11);
title(ax, ttl, 'FontSize',12,'FontWeight','bold','Interpreter','tex');
viz_style().apply(ax);
end

function histPanel(ax, Z, xlab, isPhase, nbins, faceColor, S)
v = Z(isfinite(Z));
histogram(ax, v, nbins, 'FaceColor',faceColor, 'EdgeColor',[0.2 0.2 0.2]);
if isPhase
    xlim(ax, [0 2*pi]);
end
xlabel(ax, xlab,'FontSize',S.labelSize); ylabel(ax,'Count','FontSize',S.labelSize);
S.apply(ax);
% 4 статистичні моменти (для фази — циклічне середнє); tp_moments — те саме
% джерело формул, що й у viz_stats_table.m (текстовий файл поряд), щоб
% цифри на картинці й у .txt завжди збігались.
[mu, sd, sk, ku] = tp_moments(v, isPhase);
txt = sprintf('mean = %.4g\nstd  = %.4g\nskew = %.4g\nkurt = %.4g', mu, sd, sk, ku);
text(ax, 0.97,0.97, txt, 'Units','normalized','VerticalAlignment','top', ...
     'HorizontalAlignment','right','FontName','Consolas','FontSize',9, ...
     'Color',S.ink,'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3);
end
