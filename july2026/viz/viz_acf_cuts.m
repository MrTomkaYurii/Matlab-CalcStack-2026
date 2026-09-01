function viz_acf_cuts(D, meta, ctx, CFG)
% VIZ_ACF_CUTS  Подання (4B): 1D перерізи ACF по X/Y + їх PSD у log-log.
%   Панелі 2x2: [ перерізи ACF (OX,OY) |f| | PSD перерізів log-log |f| ;
%                 перерізи ACF (OX,OY) Arg | PSD перерізів log-log Arg ].
%   Переріз по X = центральний рядок 2D ACF (vs dx); по Y = центральний стовпець.
%   PSD перерізу = FFT(ACF-перерізу) (Wiener–Khinchin), у подвійних лог-осях.
%   2D ACF НЕ рахується тут — береться готова з meta.acfData (порахована
%   ОДИН раз у tp_visualize.m і спільна з поданням (4A), viz_acf_psd).

S      = viz_style();
method = meta.acfData.method;

fig = figure('Color','w','Visible','off','Position',[60 60 1200 950]);
S.light(fig);

rows = { meta.acfData.mod, meta.modLabel; meta.acfData.arg, meta.argLabel };
for r = 1:2
    acf = rows{r,1}.acf; qlab = rows{r,2};

    cx = acf(round(size(acf,1)/2), :);          % переріз по X (vs dx)
    cy = acf(:, round(size(acf,2)/2)).';         % переріз по Y (vs dy)
    lagx = rows{r,1}.lagx; lagy = rows{r,1}.lagy;

    % ліва панель — перерізи ACF
    ax = subplot(2,2,(r-1)*2 + 1); hold(ax,'on');
    plot(ax, lagx, cx, 'Color',S.lineRed,  'LineWidth',1.5, 'DisplayName','ACF along OX');
    plot(ax, lagy, cy, 'Color',S.lineBlue, 'LineWidth',1.5, 'DisplayName','ACF along OY');
    xlabel(ax,'Lag \Delta (px)','FontSize',S.labelSize); ylabel(ax,'ACF [0..1]','FontSize',S.labelSize);
    ylim(ax,[0 1]);
    title(ax, sprintf('ACF cross-sections — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
    legend(ax,'Location','northeast'); S.apply(ax);

    % права панель — PSD перерізів у log-log
    ax = subplot(2,2,(r-1)*2 + 2);
    [fX, pX] = cutPSD(cx);
    [fY, pY] = cutPSD(cy);
    loglog(ax, fX, pX, 'Color',S.lineRed,  'LineWidth',1.5, 'DisplayName','PSD along OX'); hold(ax,'on');
    loglog(ax, fY, pY, 'Color',S.lineBlue, 'LineWidth',1.5, 'DisplayName','PSD along OY');
    xlabel(ax,'Frequency (1/px)','FontSize',S.labelSize); ylabel(ax,'PSD (a.u.)','FontSize',S.labelSize);
    title(ax, sprintf('PSD of cross-sections (log-log) — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
    legend(ax,'Location','northeast'); grid(ax,'on'); S.apply(ax);
end

sgtitle(sprintf('%s  \\cdot  ACF cross-sections & their PSD  [%s]', meta.titlePrefix, method), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_acf_cuts_%s', ctx.name, method));
end

% ------------------------------------------------------------------------
function [f, p] = cutPSD(cut)
% PSD 1D-перерізу ACF = |FFT(ACF)| (Wiener–Khinchin); лишаємо додатні частоти.
L = numel(cut);
p = abs(fft(ifftshift(cut)));      % ACF центрований у середині -> ifftshift
f = (0:L-1)/L;
pos = 2:floor(L/2);                % пропускаємо DC для log-log
f = f(pos);  p = p(pos) + eps;
end
