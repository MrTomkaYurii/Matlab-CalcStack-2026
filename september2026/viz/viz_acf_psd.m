function viz_acf_psd(D, meta, ctx, CFG)
% VIZ_ACF_PSD  Подання (4A): 2D АКФ (з вставкою-зумом на пік "картинка в
%   картинці") + 2D PSD. Панелі 2x2: [ 2D ACF |f| (+ inset) | 2D PSD |f| ;
%   те саме для Arg ].
%   ACF/PSD НЕ рахуються тут — беруться готові з meta.acfData (порахований
%   ОДИН раз у tp_visualize.m і спільний з поданням (4B), viz_acf_cuts).
%   Метод розрахунку — CFG.acf.method ('fast' | 'direct'), див. tp_acf_psd.
%
%   Вставка (inset): повний ACF (лаги аж до ±(N-1)px) робить вузький пік
%   (кілька px) невидимим на тлі всього кадру -- маленька axes-вставка у
%   кутку ТІЄЇ Ж панелі показує обрізане до вікна навколо HWHM
%   (tp_acf_hwhm.m, той самий розрахунок, що дає цифри в Block 1 / (4B))
%   зображення з ОКРЕМОЮ, локально масштабованою шкалою кольору (а не
%   фіксованою [0,1]) -- так видно форму спаду піка. На головній панелі
%   прямокутником позначено, яку саме область показує вставка.

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end
method = meta.acfData.method;

rows = { meta.acfData.mod, meta.modLabel; meta.acfData.arg, meta.argLabel };

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[60 60 1200 950]);
    S.light(fig);

    for r = 1:2
        acf = rows{r,1}.acf; psd = rows{r,1}.psd;
        lagx = rows{r,1}.lagx; lagy = rows{r,1}.lagy; qlab = rows{r,2};

        % 2D ACF -- повний діапазон + вставка-зум на пік
        ax = subplot(2,2,(r-1)*2 + 1);
        imagesc(ax, lagx, lagy, acf); set(ax,'YDir','normal'); axis(ax,'image');
        colormap(ax, cmap); caxis(ax,[0 1]);
        cb=colorbar(ax); cb.Label.String='ACF [0..1]'; cb.Color=S.ink;
        xlabel(ax,'\Delta x (px)','FontSize',S.labelSize); ylabel(ax,'\Delta y (px)','FontSize',S.labelSize);
        title(ax, sprintf('2D ACF — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
        S.apply(ax);
        addAcfZoomInset(ax, lagx, lagy, acf, cmap, S);

        % 2D PSD (dB) -- шкала обрізана за процентилями (clipPct), інакше
        % єдиний DC-піксель (v=Z-mean(Z) -> точний нуль на нульовій
        % частоті -> ~-150dB) розтягує кольорову шкалу на весь діапазон і
        % змістовні значення тиснуться в кілька % її, все виглядає "суцільно
        % червоним". Той самий принцип, що paper_figures\cfg_figures.m
        % (FIG.psd.clipPct).
        ax = subplot(2,2,(r-1)*2 + 2);
        dbMap = 10*log10(psd + eps);
        imagesc(ax, dbMap); set(ax,'YDir','normal'); axis(ax,'image');
        colormap(ax, cmap);
        clipPct = 1;   % % з кожного боку
        lo = prctile(dbMap(:), clipPct); hi = prctile(dbMap(:), 100-clipPct);
        if isfinite(lo) && isfinite(hi) && lo < hi, caxis(ax, [lo hi]); end
        cb=colorbar(ax); cb.Label.String='PSD (dB)'; cb.Color=S.ink;
        xlabel(ax,'Freq. index X','FontSize',S.labelSize); ylabel(ax,'Freq. index Y','FontSize',S.labelSize);
        title(ax, sprintf('2D PSD — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
        S.apply(ax);
    end

    sgtitle(sprintf('%s  \\cdot  2D ACF & PSD  [%s | %s]', meta.titlePrefix, method, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_acf_psd_2d_%s_%s', ctx.name, method, cmap));
end
end

% ------------------------------------------------------------------------
function addAcfZoomInset(axMain, lagx, lagy, acf, cmap, S)
% "Картинка в картинці": маленька axes-вставка у верхньому правому куті
% axMain, з ЛОКАЛЬНОЮ шкалою кольору навколо вузького піка ACF.

% --- вікно зуму: max(HWHM_x,HWHM_y)*4, мін. 5px ---
[~, ix0] = min(abs(lagx)); [~, iy0] = min(abs(lagy));
hwx = tp_acf_hwhm(lagx, acf(iy0,:));
hwy = tp_acf_hwhm(lagy, acf(:,ix0)');
hw = max([hwx, hwy], [], 'omitnan');
if isempty(hw) || isnan(hw), hw = 2.5; end
half = max(hw*4, 5);
if isinf(half), half = 10; end
half = min(half, min(max(lagx), max(lagy)));

xi = lagx >= -half & lagx <= half;
yi = lagy >= -half & lagy <= half;
zx = lagx(xi); zy = lagy(yi); zAcf = acf(yi, xi);

% --- прямокутник на головній панелі: яку область показує вставка ---
hold(axMain,'on');
rectangle(axMain, 'Position',[-half -half 2*half 2*half], ...
    'EdgeColor','w', 'LineWidth',1.5, 'LineStyle','--');
hold(axMain,'off');

% --- сама вставка: НИЖНІЙ правий кут axMain (normalized figure units) ---
posMain = get(axMain,'Position');
insetW = 0.40*posMain(3); insetH = 0.40*posMain(4);
insetPos = [posMain(1)+posMain(3)-insetW-0.012, posMain(2)+0.012, insetW, insetH];
axIn = axes('Position', insetPos);

imagesc(axIn, zx, zy, zAcf); set(axIn,'YDir','normal'); axis(axIn,'image');
colormap(axIn, cmap);
lo = min(zAcf(:)); hi = max(zAcf(:));
if isfinite(lo) && isfinite(hi) && lo < hi, caxis(axIn, [lo hi]); end   % ОКРЕМА локальна шкала
set(axIn, 'FontSize',7, 'Box','on', 'LineWidth',1.5, 'XColor','w','YColor','w', ...
    'Color','w', 'XTickLabel',[], 'YTickLabel',[]);
title(axIn, sprintf('zoom \\pm%.0fpx', half), 'FontSize',7, 'Color','w', 'FontWeight','bold','Interpreter','tex');
cbIn = colorbar(axIn); cbIn.FontSize = 6; cbIn.Color = 'w';
end
