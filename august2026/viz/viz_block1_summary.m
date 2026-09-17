function viz_block1_summary(D, meta, ctx, CFG)
% VIZ_BLOCK1_SUMMARY  Блок 1 за ТЗ ("Мапа модуля - мапа аргумента, під ними
%   гістограми, під ними АКФ"), ОДНІЄЮ фігурою (3 рядки x 2 стовпці):
%     ряд 1: карта модуля       | карта аргументу
%     ряд 2: гістограма модуля  | гістограма аргументу
%     ряд 3: АКФ-переріз модуля | АКФ-переріз аргументу  (наближено до
%            піка + позначена півширина HWHM — як у viz_acf_cuts.m)
%   Доповнює (не замінює) окремі viz_maps_hist / viz_acf_cuts — тут те саме
%   подається в ОДНОМУ узгодженому блоці для швидкого огляду.

S      = viz_style();
method = 'n/a';
if ~isempty(meta.acfData), method = meta.acfData.method; end

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[60 40 1200 1300]);
    S.light(fig);

    % ряд 1 — карти
    mapPanel(subplot(3,2,1), meta.x, meta.y, D.mod, cmap, meta, meta.modLabel, ...
             sprintf('Module map  %s', meta.modLabel), S, false);
    mapPanel(subplot(3,2,2), meta.x, meta.y, D.arg, cmap, meta, meta.argLabel, ...
             sprintf('Argument map  %s', meta.argLabel), S, true);

    % ряд 2 — гістограми
    histPanel(subplot(3,2,3), D.mod, meta.modLabel, false, CFG.viz.histBins, [0.20 0.40 0.80], S);
    title(gca,'Histogram of module','FontSize',S.subSize,'FontWeight','bold');
    histPanel(subplot(3,2,4), D.arg, meta.argLabel, true, CFG.viz.histBins, [0.80 0.40 0.20], S);
    title(gca,'Histogram of argument','FontSize',S.subSize,'FontWeight','bold');

    % ряд 3 — АКФ-перерізи (наближено, з HWHM), якщо є meta.acfData
    if ~isempty(meta.acfData)
        acfPanel(subplot(3,2,5), meta.acfData.mod, 'Module', S);
        acfPanel(subplot(3,2,6), meta.acfData.arg, 'Argument', S);
    else
        axis(subplot(3,2,5),'off'); axis(subplot(3,2,6),'off');
    end

    sgtitle(sprintf('%s  \\cdot  Block 1: maps + histograms + ACF  [%s | %s]', ...
            meta.titlePrefix, method, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('_block1_%s_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function mapPanel(ax, x, y, Z, cmap, meta, cbLabel, ttl, S, isPhase)
im = imagesc(ax, x, y, Z); set(im,'AlphaData',isfinite(Z));
set(ax,'YDir','normal'); axis(ax,'image'); colormap(ax, cmap);
if isPhase
    caxis(ax, [-pi pi]);
else
    lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
    if isfinite(lo) && isfinite(hi) && lo<hi, caxis(ax,[lo hi]); end
end
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = S.ink;
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

% ------------------------------------------------------------------------
function histPanel(ax, Z, xlab, isPhase, nbins, faceColor, S)
v = Z(isfinite(Z));
histogram(ax, v, nbins, 'FaceColor',faceColor, 'EdgeColor',[0.2 0.2 0.2]);
if isPhase
    xlim(ax, [-pi pi]);
end
xlabel(ax, xlab,'FontSize',S.labelSize); ylabel(ax,'Count','FontSize',S.labelSize);
S.apply(ax);
[mu, sd, sk, ku] = tp_moments(v, isPhase);
txt = sprintf('mean = %.4g\nstd  = %.4g\nskew = %.4g\nkurt = %.4g', mu, sd, sk, ku);
text(ax, 0.97,0.97, txt, 'Units','normalized','VerticalAlignment','top', ...
     'HorizontalAlignment','right','FontName','Consolas','FontSize',9, ...
     'Color',S.ink,'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3);
end

% ------------------------------------------------------------------------
function acfPanel(ax, acfEntry, qlab, S)
% Переріз ACF по X/Y, наближено до піка (щоб було видно півширину),
% з позначеною HWHM — та сама логіка, що й у viz_acf_cuts.m.
acf = acfEntry.acf; lagx = acfEntry.lagx; lagy = acfEntry.lagy;
cx = acf(round(size(acf,1)/2), :);
cy = acf(:, round(size(acf,2)/2)).';

[hwX, loX, hiX] = halfWidthEstimate(lagx, cx);
[hwY, loY, hiY] = halfWidthEstimate(lagy, cy);
xl = zoomRangeFor(lagx, cx, lagy, cy);

hold(ax,'on');
plot(ax, [xl(1) xl(2)], [0.5 0.5], ':', 'Color',[0.5 0.5 0.5], 'LineWidth',1, 'HandleVisibility','off');
plot(ax, lagx, cx, 'Color',S.lineRed,  'LineWidth',1.5, 'DisplayName','ACF along OX');
plot(ax, lagy, cy, 'Color',S.lineBlue, 'LineWidth',1.5, 'DisplayName','ACF along OY');
markHalfWidth(ax, loX, hiX, S.lineRed);
markHalfWidth(ax, loY, hiY, S.lineBlue);
xlabel(ax,'Lag \Delta (px)','FontSize',S.labelSize); ylabel(ax,'ACF [0..1]','FontSize',S.labelSize);
xlim(ax, xl); ylim(ax,[0 1]);
title(ax, sprintf('ACF cross-section — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
legend(ax,'Location','northeast');
text(ax, 0.03,0.05, sprintf('HWHM: OX=%.2f px, OY=%.2f px', hwX, hwY), ...
     'Units','normalized','FontName','Consolas','FontSize',9,'Color',S.ink, ...
     'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3);
S.apply(ax);
end

% ------------------------------------------------------------------------
function [hw, loLag, hiLag] = halfWidthEstimate(lag, curve)
[~, i0] = min(abs(lag));
peak = curve(i0); half = 0.5*peak;
hiLag = NaN;
for i = i0:numel(curve)-1
    if curve(i) >= half && curve(i+1) < half
        t = (half - curve(i)) / (curve(i+1) - curve(i));
        hiLag = lag(i) + t*(lag(i+1)-lag(i)); break;
    end
end
loLag = NaN;
for i = i0:-1:2
    if curve(i) >= half && curve(i-1) < half
        t = (half - curve(i)) / (curve(i-1) - curve(i));
        loLag = lag(i) + t*(lag(i-1)-lag(i)); break;
    end
end
if isnan(hiLag) && isnan(loLag), hw = NaN;
elseif isnan(hiLag), hw = 2*abs(loLag);
elseif isnan(loLag), hw = 2*abs(hiLag);
else, hw = hiLag - loLag;
end
end

function markHalfWidth(ax, loLag, hiLag, color)
if isfinite(loLag), xline(ax, loLag, ':', 'Color',color, 'LineWidth',1, 'HandleVisibility','off'); end
if isfinite(hiLag), xline(ax, hiLag, ':', 'Color',color, 'LineWidth',1, 'HandleVisibility','off'); end
end

function xl = zoomRangeFor(lagx, cx, lagy, cy)
rX = decayRange(lagx, cx, 0.1);
rY = decayRange(lagy, cy, 0.1);
r  = max(rX, rY);
if ~isfinite(r) || r <= 0
    xl = [min(lagx(1),lagy(1)), max(lagx(end),lagy(end))];
else
    r  = 1.2*r; xl = [-r, r];
end
end

function r = decayRange(lag, curve, level)
[~, i0] = min(abs(lag));
peak = curve(i0); thr = level*peak; r = NaN;
for i = i0:numel(curve)-1
    if curve(i+1) < thr, r = max(abs(lag(i+1)), abs(lag(i))); break; end
end
end
