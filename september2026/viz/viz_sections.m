function viz_sections(D, meta, ctx, CFG)
% VIZ_SECTIONS  Подання (2) за ескізом: 2x2 контурні карти + 3D-поверхні.
%   Панелі: [ контур |f| з числами | контур Arg з числами ; 3D |f| | 3D Arg ].
%   По одній фігурі на кожну colormap. Стиль — за old/calc_2025_vis_DvotMM (Частина 03).

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end
nL = CFG.viz.contourLevels;

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 950]);
    S.light(fig);

    % (1) контур модуля з підписаними рівнями (лінії — по злегка згладженому
    %     полю, щоб на шумних реальних даних не розсипались на плями;
    %     3D-поверхня нижче лишається на сирих даних, без згладжування)
    smoothPx = 0; if isfield(CFG.viz,'contourSmoothPx'), smoothPx = CFG.viz.contourSmoothPx; end
    ax = subplot(2,2,1);
    contourPanel(ax, meta.x, meta.y, D.mod, cmap, nL, meta, meta.modLabel, ...
                 sprintf('Module contour  %s', meta.modLabel), S, smoothPx);

    % (2) контур аргументу
    ax = subplot(2,2,2);
    contourPanel(ax, meta.x, meta.y, D.arg, cmap, nL, meta, meta.argLabel, ...
                 sprintf('Argument contour  %s', meta.argLabel), S, smoothPx);

    % (3) 3D-поверхня модуля
    ax = subplot(2,2,3);
    surfPanel(ax, meta.x, meta.y, D.mod, cmap, meta, meta.modLabel, ...
              sprintf('Module 3D surface  %s', meta.modLabel), S);

    % (4) 3D-поверхня аргументу
    ax = subplot(2,2,4);
    surfPanel(ax, meta.x, meta.y, D.arg, cmap, meta, meta.argLabel, ...
              sprintf('Argument 3D surface  %s', meta.argLabel), S);

    sgtitle(sprintf('%s  \\cdot  contours & 3D surfaces  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);

    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_surf_contour_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function contourPanel(ax, x, y, Z, cmap, nL, meta, cbLabel, ttl, S, smoothPx)
% Лінії контуру рахуються по ЗГЛАДЖЕНОМУ полю (smoothPx, NaN-безпечно) —
% на шумних реальних даних лінії інакше рвуться на плями, бо contour()
% малює тільки там, де значення точно перетинає рівень. Діапазон/легенда
% рахуються від того самого (згладженого) поля, щоб рівні відповідали
% тому, що реально намальовано.
if nargin < 11, smoothPx = 0; end
Zc = tp_smooth2(Z, smoothPx);

[lo, hi, levels] = tp_contour_levels(Zc, nL);
[C,~] = contour(ax, x, y, Zc, levels, 'LineWidth',1.2);  % кольорові лінії за рівнем
colormap(ax, cmap); caxis(ax,[lo hi]); axis(ax,'image'); set(ax,'YDir','normal');
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = S.ink;
cb.Ticks = levels; cb.TickLabels = arrayfun(@tp_format_level, levels, 'UniformOutput', false);
labelContoursDistributed(ax, C, min(x), max(x), min(y), max(y));  % цифри рівномірно знизу вгору,
                                                                   % по 1 на рівень, з лінією-вказівником
if smoothPx > 0
    ttl = sprintf('%s  (smoothed \\sigma=%.0fpx)', ttl, smoothPx);
end
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

function labelContoursDistributed(ax, C, xlo, xhi, ylo, yhi)
% Одна цифра на кожен рівень контуру, рознесені РІВНОМІРНО по всій висоті осі Y
% (знизу вгору) в колонці біля лівого краю панелі, з ТОНКОЮ ЛІНІЄЮ-ВКАЗІВНИКОМ
% до фактичної точки на лінії контуру — однозначніше за колір-у-колір
% (кольори сусідніх рівнів у colormap можуть бути схожі й важко розрізнити
% на дрібному друці/екрані), і простий чорний текст читається найкраще.
i = 1; lv = []; VX = {}; VY = {};
while i < size(C,2)                       % зібрати вершини по кожному рівню
    lvl = C(1,i); n = C(2,i); seg = C(:, i+1:i+n);
    j = find(abs(lv - lvl) < 1e-9, 1);
    if isempty(j)
        lv(end+1) = lvl;  VX{end+1} = seg(1,:);  VY{end+1} = seg(2,:); %#ok<AGROW>
    else
        VX{j} = [VX{j}, seg(1,:)];  VY{j} = [VY{j}, seg(2,:)];
    end
    i = i + n + 1;
end
[lv, order] = sort(lv);  VX = VX(order);  VY = VY(order);   % знизу вгору за значенням
L = numel(lv);
labelX = xlo + 0.08*(xhi - xlo);             % колонка підписів біля лівого краю
hold(ax, 'on');   % щоб plot() ліній-вказівників НЕ стер уже намальований контур
for j = 1:L
    ty = ylo + (j - 0.5)/L * (yhi - ylo);        % рівномірна смуга для цього рівня
    [~, mi] = min(abs(VY{j} - ty));              % вершина, найближча до смуги
    tx = VX{j}(mi); tyPt = VY{j}(mi);            % фактична точка НА лінії
    plot(ax, [labelX tx], [ty tyPt], '-', 'Color',[0.25 0.25 0.25], ...
         'LineWidth',0.7, 'HandleVisibility','off');
    plot(ax, tx, tyPt, 'o', 'MarkerSize',4, 'MarkerFaceColor','k', ...
         'MarkerEdgeColor','k', 'HandleVisibility','off');
    text(ax, labelX, ty, tp_format_level(lv(j)), 'FontSize',10, ...
         'FontWeight','bold', 'Color','k', 'BackgroundColor','w', ...
         'EdgeColor',[0.3 0.3 0.3], 'Margin',2, ...
         'HorizontalAlignment','center', 'Clipping','on');
end
end

function surfPanel(ax, x, y, Z, cmap, meta, zlab, ttl, S)
surf(ax, x, y, Z, 'EdgeColor','none'); shading(ax,'interp');
colormap(ax, cmap); view(ax,45,30);
lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if isfinite(lo) && isfinite(hi) && lo<hi, caxis(ax,[lo hi]); end
cb = colorbar(ax); cb.Label.String = zlab; cb.Color = S.ink;
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
zlabel(ax, zlab,'FontSize',S.labelSize);
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end
