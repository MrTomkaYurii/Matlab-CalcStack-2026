function viz_acf_psd(D, meta, ctx, CFG)
% VIZ_ACF_PSD  Подання (4A): 2D АКФ + 2D PSD.
%   Панелі 2x2: [ 2D ACF |f| | 2D PSD |f| ; 2D ACF Arg | 2D PSD Arg ].
%   ACF/PSD НЕ рахуються тут — беруться готові з meta.acfData (порахований
%   ОДИН раз у tp_visualize.m і спільний з поданням (4B), viz_acf_cuts).
%   Метод розрахунку — CFG.acf.method ('fast' | 'direct'), див. tp_acf_psd.

S      = viz_style();
method = meta.acfData.method;

rows = { meta.acfData.mod, meta.modLabel; meta.acfData.arg, meta.argLabel };

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[60 60 1200 950]);
    S.light(fig);

    for r = 1:2
        acf = rows{r,1}.acf; psd = rows{r,1}.psd;
        lagx = rows{r,1}.lagx; lagy = rows{r,1}.lagy; qlab = rows{r,2};

        % 2D ACF
        ax = subplot(2,2,(r-1)*2 + 1);
        imagesc(ax, lagx, lagy, acf); set(ax,'YDir','normal'); axis(ax,'image');
        colormap(ax, cmap); caxis(ax,[0 1]);
        cb=colorbar(ax); cb.Label.String='ACF [0..1]'; cb.Color=S.ink;
        xlabel(ax,'\Delta x (px)','FontSize',S.labelSize); ylabel(ax,'\Delta y (px)','FontSize',S.labelSize);
        title(ax, sprintf('2D ACF — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
        S.apply(ax);

        % 2D PSD (dB)
        ax = subplot(2,2,(r-1)*2 + 2);
        imagesc(ax, 10*log10(psd + eps)); set(ax,'YDir','normal'); axis(ax,'image');
        colormap(ax, cmap); cb=colorbar(ax); cb.Label.String='PSD (dB)'; cb.Color=S.ink;
        xlabel(ax,'Freq. index X','FontSize',S.labelSize); ylabel(ax,'Freq. index Y','FontSize',S.labelSize);
        title(ax, sprintf('2D PSD — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
        S.apply(ax);
    end

    sgtitle(sprintf('%s  \\cdot  2D ACF & PSD  [%s | %s]', meta.titlePrefix, method, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_acf_psd_2d_%s_%s', ctx.name, method, cmap));
end
end
