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
             sprintf('Module  %s', meta.modLabel));

    % (2) карта аргументу
    ax = subplot(2,2,2);
    mapPanel(ax, meta.x, meta.y, D.arg, cmap, meta, meta.argLabel, ...
             sprintf('Argument  %s', meta.argLabel));

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
function mapPanel(ax, x, y, Z, cmap, meta, cbLabel, ttl)
im = imagesc(ax, x, y, Z); set(im,'AlphaData',isfinite(Z));
set(ax,'YDir','normal'); axis(ax,'image');
colormap(ax, cmap);
lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if isfinite(lo) && isfinite(hi) && lo<hi, caxis(ax,[lo hi]); end
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = [0.12 0.12 0.12];
xlabel(ax, meta.xlabel,'FontSize',11); ylabel(ax, meta.ylabel,'FontSize',11);
title(ax, ttl, 'FontSize',12,'FontWeight','bold','Interpreter','tex');
viz_style().apply(ax);
end

function histPanel(ax, Z, xlab, isPhase, nbins, faceColor, S)
v = Z(isfinite(Z));
histogram(ax, v, nbins, 'FaceColor',faceColor, 'EdgeColor',[0.2 0.2 0.2]);
xlabel(ax, xlab,'FontSize',S.labelSize); ylabel(ax,'Count','FontSize',S.labelSize);
S.apply(ax);
% 4 статистичні моменти (для фази — циклічне середнє)
if isPhase
    mu = angle(mean(exp(1i*v)));
    cc = atan2(sin(v-mu), cos(v-mu));   % центровані кути
    sd = std(v); sk = moment3(cc); ku = moment4(cc);
else
    mu = mean(v); sd = std(v); z = (v-mu)/max(sd,eps);
    sk = mean(z.^3); ku = mean(z.^4);
end
txt = sprintf('mean = %.4g\nstd  = %.4g\nskew = %.4g\nkurt = %.4g', mu, sd, sk, ku);
text(ax, 0.97,0.97, txt, 'Units','normalized','VerticalAlignment','top', ...
     'HorizontalAlignment','right','FontName','Consolas','FontSize',9, ...
     'Color',S.ink,'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3);
end

function s = moment3(cc)
sd = std(cc); z = cc/max(sd,eps); s = mean(z.^3);
end
function k = moment4(cc)
sd = std(cc); z = cc/max(sd,eps); k = mean(z.^4);
end
