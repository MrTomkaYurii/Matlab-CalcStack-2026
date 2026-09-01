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

    % ліва панель — перерізи ACF, наближено до піка (щоб було видно
    % півширину, а не губити її на весь діапазон лагу ±N/2)
    [hwX, loX, hiX] = tp_acf_hwhm(lagx, cx);
    [hwY, loY, hiY] = tp_acf_hwhm(lagy, cy);
    xl = zoomRangeFor(lagx, cx, lagy, cy);

    ax = subplot(2,2,(r-1)*2 + 1); hold(ax,'on');
    plot(ax, [xl(1) xl(2)], [0.5 0.5], ':', 'Color',[0.5 0.5 0.5], 'LineWidth',1, 'HandleVisibility','off');
    plot(ax, lagx, cx, 'Color',S.lineRed,  'LineWidth',1.5, 'DisplayName','ACF along OX');
    plot(ax, lagy, cy, 'Color',S.lineBlue, 'LineWidth',1.5, 'DisplayName','ACF along OY');
    markHalfWidth(ax, loX, hiX, S.lineRed);
    markHalfWidth(ax, loY, hiY, S.lineBlue);
    xlabel(ax,'Lag \Delta (px)','FontSize',S.labelSize); ylabel(ax,'ACF [0..1]','FontSize',S.labelSize);
    xlim(ax, xl); ylim(ax,[0 1]);
    title(ax, sprintf('ACF cross-sections — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
    legend(ax,'Location','northeast');
    text(ax, 0.03,0.05, sprintf('HWHM: OX=%.2f px, OY=%.2f px', hwX, hwY), ...
         'Units','normalized','FontName','Consolas','FontSize',9,'Color',S.ink, ...
         'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',3);
    S.apply(ax);

    % права панель — PSD перерізів у log-log, з ДВОСЕГМЕНТНОЮ апроксимацією
    % (замість однієї прямої на весь діапазон): реальні дані типово мають
    % "коліно" між пологою й крутішою ділянкою, а високочастотний хвіст
    % часто взагалі плаский (=шумовий поріг вимірювання, не сигнал) —
    % tp_piecewise_loglog_fit.m позначає це окремо.
    ax = subplot(2,2,(r-1)*2 + 2);
    [fX, pX] = cutPSD(cx);
    [fY, pY] = cutPSD(cy);
    loglog(ax, fX, pX, 'Color',S.lineRed,  'LineWidth',1.5, 'DisplayName','PSD along OX'); hold(ax,'on');
    loglog(ax, fY, pY, 'Color',S.lineBlue, 'LineWidth',1.5, 'DisplayName','PSD along OY');
    infoX = plotPiecewiseFit(ax, fX, pX, S.lineRed);
    infoY = plotPiecewiseFit(ax, fY, pY, S.lineBlue);
    xlabel(ax,'Frequency (1/px)','FontSize',S.labelSize); ylabel(ax,'PSD (a.u.)','FontSize',S.labelSize);
    title(ax, sprintf('PSD of cross-sections (log-log) — %s', qlab),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
    legend(ax,'Location','northeast'); grid(ax,'on');
    text(ax, 0.03,0.05, sprintf('OX: %s\nOY: %s', infoX, infoY), 'Units','normalized', ...
         'VerticalAlignment','bottom','FontName','Consolas','FontSize',7.5,'Color',S.ink, ...
         'BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',2,'Interpreter','tex');
    S.apply(ax);
end

sgtitle(sprintf('%s  \\cdot  ACF cross-sections & their PSD  [%s]', meta.titlePrefix, method), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_acf_cuts_%s', ctx.name, method));
end

% ------------------------------------------------------------------------
function markHalfWidth(ax, loLag, hiLag, color)
% Вертикальні пунктирні маркери на межах HWHM (якщо знайдені).
if isfinite(loLag)
    xline(ax, loLag, ':', 'Color',color, 'LineWidth',1, 'HandleVisibility','off');
end
if isfinite(hiLag)
    xline(ax, hiLag, ':', 'Color',color, 'LineWidth',1, 'HandleVisibility','off');
end
end

% ------------------------------------------------------------------------
function xl = zoomRangeFor(lagx, cx, lagy, cy)
% Діапазон лагу для наближення: доки обидва перерізи не спадуть нижче 0.1
% від свого піка (per ТЗ: "вісь абсцис у малих межах, напр. 1-0.1"), плюс
% запас 20%. Якщо крива не спадає нижче 0.1 в межах даних — весь діапазон.
rX = decayRange(lagx, cx, 0.1);
rY = decayRange(lagy, cy, 0.1);
r  = max(rX, rY);
if ~isfinite(r) || r <= 0
    xl = [min(lagx(1),lagy(1)), max(lagx(end),lagy(end))];
else
    r  = 1.2*r;
    xl = [-r, r];
end
end

function r = decayRange(lag, curve, level)
[~, i0] = min(abs(lag));
peak = curve(i0);
thr  = level*peak;
r = NaN;
for i = i0:numel(curve)-1
    if curve(i+1) < thr
        r = max(abs(lag(i+1)), abs(lag(i)));
        break;
    end
end
end

% ------------------------------------------------------------------------
function info = plotPiecewiseFit(ax, f, p, color)
% Малює обидва сегменти апроксимації (пунктир, лише над СВОЄЮ ділянкою
% частот — не через увесь графік) і, якщо другий сегмент майже плаский,
% затінює його як шумовий поріг. Повертає короткий текст для анотації.
fit = tp_piecewise_loglog_fit(f, p);
if ~fit.valid
    info = 'n/a'; return;
end

if fit.isNoiseFloor2
    yl = ylim(ax);
    xPatch = [10^fit.seg2.lf(1), 10^fit.seg2.lf(2), 10^fit.seg2.lf(2), 10^fit.seg2.lf(1)];
    yPatch = [yl(1), yl(1), yl(2), yl(2)];
    patch(ax, xPatch, yPatch, [0.5 0.5 0.5], 'FaceAlpha',0.12, 'EdgeColor','none', 'HandleVisibility','off');
    ylim(ax, yl);
end

plotSeg(ax, fit.seg1, color, '--');
plotSeg(ax, fit.seg2, color, ':');

if fit.isNoiseFloor2
    info = sprintf('\\beta_1=%.2f (f<%.3g), noise floor above', fit.seg1.beta, fit.breakF);
else
    info = sprintf('\\beta_1=%.2f, \\beta_2=%.2f (break f=%.3g)', fit.seg1.beta, fit.seg2.beta, fit.breakF);
end
end

function plotSeg(ax, seg, color, style)
xf = seg.lf;
yf = polyval(seg.coef, xf);
plot(ax, 10.^xf, 10.^yf, style, 'Color',color, 'LineWidth',1.2, 'HandleVisibility','off');
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
