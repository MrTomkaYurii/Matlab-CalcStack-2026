function viz_overview(R, dir, baseParts, titlePrefix, CFG)
% VIZ_OVERVIEW  Частина 01: оглядові сітки 4x4 (усі 16 f_ik на одній фігурі).
%   Дві фігури на кожну colormap: усі модулі, усі аргументи.
%   Зберігаються на рівні кроку (baseParts) з префіксом 00_ (щоб були зверху).

S  = viz_style();
ax = R.axes.(dir);
sets = { {'mod','Modules  |f_{ik}|','modules'}, ...
         {'arg','Arguments  Arg(f_{ik}) [rad]','arguments'} };

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    for qs = 1:numel(sets)
        qk = sets{qs}{1}; qttl = sets{qs}{2}; qtag = sets{qs}{3};

        fig = figure('Color','w','Visible','off','Position',[40 40 1500 1050]);
        S.light(fig);
        for i = 1:4
            for k = 1:4
                elem = sprintf('f%d%d', i, k);
                axp = subplot(4,4,(i-1)*4 + k);
                if ~isfield(R.data.(dir), elem), axis(axp,'off'); continue; end
                Z = R.data.(dir).(elem).(qk);
                im = imagesc(axp, ax.x, ax.y, Z); set(im,'AlphaData',isfinite(Z));
                set(axp,'YDir','normal'); axis(axp,'image');
                if strcmp(qk,'arg')   % Arg — у [0, 2pi], циклічна палітра
                    set(im,'CData',mod(Z,2*pi)); colormap(axp, viz_arg_cmap(cmap)); caxis(axp,[0 2*pi]);
                else
                    colormap(axp, cmap);
                    lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
                    if isfinite(lo)&&isfinite(hi)&&lo<hi, caxis(axp,[lo hi]); end
                end
                colorbar(axp);
                title(axp, sprintf('f_{%d%d}', i, k),'FontSize',10,'FontWeight','bold','Interpreter','tex');
                S.apply(axp);
            end
        end
        sgtitle(sprintf('%s  \\cdot  %s  [%s]', titlePrefix, qttl, cmap), ...
                'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
        tp_save_figure(fig, CFG, baseParts, sprintf('00_overview_%s_%s', qtag, cmap));
    end
end
end
