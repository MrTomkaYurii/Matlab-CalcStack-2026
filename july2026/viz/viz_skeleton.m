function viz_skeleton(D, meta, ctx, CFG)
% VIZ_SKELETON  Подання (5) за ескізом: вейвлет-скелетон + гістограма максимумів.
%   Скелетон = лінії локальних максимумів |W(a,b)| (WTMM) у площині (b, a).
%   Гістограма F(h) = розподіл значень цих максимумів (модулів амплітуд
%   вейвлет-коефіцієнтів). Робиться для модуля й аргументу f_ik.
%   Будується у кожній colormap зі списку CFG.viz.colormaps (jet, gray).
%   Панелі: [ Sup(|f|) скелетон | F(h) |f| ; Sup(Arg) скелетон | F(h) Arg ].
%   Потребує Wavelet Toolbox (cwtfilterbank / wt).

S = viz_style();

% CWT і WTMM-скелетон НЕ залежать від colormap — рахуємо ОДИН раз
% для модуля й аргументу, а не на кожен colormap.
compMod = computeSkeleton(D.mod, meta, CFG);
compArg = computeSkeleton(D.arg, meta, CFG);

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[60 60 1300 950]);
    S.light(fig);

    renderSkeletonPair(subplot(2,2,1), subplot(2,2,2), compMod, meta.modLabel, CFG, S, cmap);
    renderSkeletonPair(subplot(2,2,3), subplot(2,2,4), compArg, meta.argLabel, CFG, S, cmap);

    sgtitle(sprintf('%s  \\cdot  wavelet skeleton + F(h) of maxima  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_skeleton_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function comp = computeSkeleton(Z, meta, CFG)
% Профіль + CWT + вилучення скелетону (WTMM) — важка частина, рахується раз.
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
sr = CFG.wavelet.scaleRange;
keep = scal>=sr(1) & scal<=sr(2);
if any(keep), scal = scal(keep); A = A(keep,:); end

% скелетон: локальні максимуми вздовж b на кожному масштабі (WTMM)
[ns, ~] = size(A);
Bpts = []; Apts = []; Hpts = [];
for r = 1:ns
    idx = find(islocalmax(A(r,:)));
    Bpts = [Bpts, b(idx)];                          %#ok<AGROW>
    Apts = [Apts, repmat(scal(r), 1, numel(idx))];  %#ok<AGROW>
    Hpts = [Hpts, A(r,idx)];                        %#ok<AGROW>
end

comp.degenerate = false;
comp.Bpts = Bpts; comp.Apts = Apts; comp.Hpts = Hpts;
end

% ------------------------------------------------------------------------
function renderSkeletonPair(axSkel, axHist, comp, qLabel, CFG, S, cmap)
if comp.degenerate
    title(axSkel,'(degenerate profile)'); return;
end
Bpts = comp.Bpts; Apts = comp.Apts; Hpts = comp.Hpts;

% ліва панель — скелетон у площині (b, a), колір = амплітуда максимуму
scatter(axSkel, Bpts, Apts, 10, Hpts, 'filled');
set(axSkel,'YScale','log'); colormap(axSkel, cmap);
cb = colorbar(axSkel); cb.Label.String='|W| at maxima'; cb.Color=S.ink;
xlabel(axSkel,'Translation b (px)','FontSize',S.labelSize); ylabel(axSkel,'Scale a','FontSize',S.labelSize);
title(axSkel, sprintf('Skeleton (WTMM) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(axSkel);

% права панель — гістограма F(h) розподілу максимумів
histogram(axHist, Hpts, CFG.viz.histBins, 'FaceColor',[0.30 0.55 0.35], 'EdgeColor',[0.2 0.2 0.2]);
xlabel(axHist,'h = |W| at maxima','FontSize',S.labelSize); ylabel(axHist,'F(h)  (count)','FontSize',S.labelSize);
title(axHist, sprintf('Distribution of maxima — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
if ~isempty(Hpts)
    text(axHist, 0.97,0.97, sprintf('N_{max} = %d\nmean = %.3g\nstd  = %.3g', numel(Hpts), mean(Hpts), std(Hpts)), ...
        'Units','normalized','VerticalAlignment','top','HorizontalAlignment','right', ...
        'FontName','Consolas','FontSize',9,'Color',S.ink,'BackgroundColor','w', ...
        'EdgeColor',[0.6 0.6 0.6],'Margin',3);
end
S.apply(axHist);
end
