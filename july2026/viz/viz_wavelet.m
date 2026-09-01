function viz_wavelet(D, meta, ctx, CFG)
% VIZ_WAVELET  Подання (3) за ескізом: 2x2 вейвлет W(a,b).
%   Панелі: [ скалограма |f| | профілі A(b) a=10/50 ; скалограма Arg | профілі Arg ].
%   Будується у кожній colormap зі списку CFG.viz.colormaps (jet, gray).
%   Профіль беремо з карти за CFG.wavelet.profile; масштаби обмежені scaleRange.
%   Потребує Wavelet Toolbox (cwtfilterbank / wt).

S = viz_style();

% CWT НЕ залежить від colormap (це лише спосіб малювання) — рахуємо
% ОДИН раз для модуля й аргументу, а не на кожен colormap.
compMod = computeWavelet(D.mod, meta, CFG);
compArg = computeWavelet(D.arg, meta, CFG);

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 950]);
    S.light(fig);

    renderWaveletPair(subplot(2,2,1), subplot(2,2,2), compMod, meta.modLabel, S, cmap);
    renderWaveletPair(subplot(2,2,3), subplot(2,2,4), compArg, meta.argLabel, S, cmap);

    sgtitle(sprintf('%s  \\cdot  wavelet W(a,b)  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_wavelet_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function comp = computeWavelet(Z, meta, CFG)
% Профіль із карти + CWT (важка частина) — рахується один раз.
switch lower(CFG.wavelet.profile)
    case 'center_col', sig = Z(:, round(size(Z,2)/2)).';  b = meta.y;
    case 'mean_row',   sig = mean(Z,1,'omitnan');         b = meta.x;
    otherwise,         sig = Z(round(size(Z,1)/2), :);    b = meta.x;
end
sig = fillmissing(sig,'linear'); sig = fillmissing(sig,'nearest');

comp = struct('degenerate', true);
if all(~isfinite(sig)) || std(sig(isfinite(sig)))==0
    return;
end

fb = cwtfilterbank('SignalLength',numel(sig),'Wavelet',CFG.wavelet.name, ...
                   'VoicesPerOctave',CFG.wavelet.voicesPerOctave);
[wtc,~] = wt(fb, sig);  scal = scales(fb);  A = abs(wtc);

sr = CFG.wavelet.scaleRange;             % обмеження масштабів (напр. [1 100])
keep = scal>=sr(1) & scal<=sr(2);
if any(keep), scal = scal(keep); A = A(keep,:); end

hs = CFG.wavelet.highlightScales;        % [10 50]
[~,i1] = min(abs(scal-hs(1)));  [~,i2] = min(abs(scal-hs(2)));

comp.degenerate = false;
comp.b = b; comp.scal = scal; comp.A = A; comp.i1 = i1; comp.i2 = i2;
end

% ------------------------------------------------------------------------
function renderWaveletPair(axScalo, axProf, comp, qLabel, S, cmap)
if comp.degenerate
    title(axScalo,'(degenerate profile)'); return;
end
b = comp.b; scal = comp.scal; A = comp.A; i1 = comp.i1; i2 = comp.i2;

% ліва панель — скалограма
pcolor(axScalo, b, scal, A); shading(axScalo,'interp'); set(axScalo,'YScale','log');
colormap(axScalo, cmap); cb = colorbar(axScalo);
cb.Label.String = '|W(a,b)|'; cb.Color = S.ink;
hold(axScalo,'on');
yline(axScalo, scal(i1), '-', 'Color',S.lineRed,  'LineWidth',1.5, 'Label','a=10');
yline(axScalo, scal(i2), '-', 'Color',S.lineBlue, 'LineWidth',1.5, 'Label','a=50');
xlabel(axScalo,'Translation b (px)','FontSize',S.labelSize); ylabel(axScalo,'Scale a','FontSize',S.labelSize);
title(axScalo, sprintf('Scalogram W(a,b) of %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(axScalo);

% права панель — профілі на виділених масштабах
hold(axProf,'on');
plot(axProf, b, A(i1,:), 'Color',S.lineRed,  'LineWidth',1.6, 'DisplayName',sprintf('a = %.0f', scal(i1)));
plot(axProf, b, A(i2,:), 'Color',S.lineBlue, 'LineWidth',1.6, 'DisplayName',sprintf('a = %.0f', scal(i2)));
xlabel(axProf,'Translation b (px)','FontSize',S.labelSize); ylabel(axProf,'|W(a,b)|','FontSize',S.labelSize);
title(axProf, sprintf('Coefficients A(b) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
legend(axProf,'Location','northeast'); S.apply(axProf);
end
