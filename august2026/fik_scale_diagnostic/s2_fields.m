function R = s2_fields(C, paths, U, IMG, meta)
% S2_FIELDS  Крок 2 — сирі реконструйовані поля Ex, Ey (вхід усього конвеєра).
%   Для кожного стану: |Ex|, arg(Ex), |Ey|, arg(Ey) + гістограма |Ex|,|Ey|.
%   Фіксуємо масштаб |E| — це ПЕРШЕ місце, де зʼявляється ~1e-3.
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

states = {'in0','in45','in90','in135','inliv','inprav'};
labels = {'0°','45°','90°','135°','ліва цирк.','права цирк.'};

allAbs = [];  perState = struct('name',{},'mAbs',{});
for s = 1:numel(states)
    P = states{s};  Ex = IMG.(P).Ex;  Ey = IMG.(P).Ey;
    aE = abs([Ex(:); Ey(:)]);  allAbs = [allAbs; aE(aE>0)]; %#ok<AGROW>
    perState(end+1) = struct('name',labels{s}, ...
        'mAbs', mean(aE(aE>0),'omitnan')); %#ok<AGROW>

    fig = figure('Color','w','Visible','off','Position',[50 50 1200 780]);
    U.panel(subplot(2,3,1), abs(Ex),   sprintf('|Ex|  %s', labels{s}), C.fig.cmapMod, C);
    U.panel(subplot(2,3,2), angle(Ex), 'arg(Ex), рад',                 C.fig.cmapArg, C);
    U.hist (subplot(2,3,3), abs(Ex),   '|Ex| — розподіл',              C);
    U.panel(subplot(2,3,4), abs(Ey),   sprintf('|Ey|  %s', labels{s}), C.fig.cmapMod, C);
    U.panel(subplot(2,3,5), angle(Ey), 'arg(Ey), рад',                 C.fig.cmapArg, C);
    U.hist (subplot(2,3,6), abs(Ey),   '|Ey| — розподіл',              C);
    sgtitle(sprintf(['Крок 2. Сирі реконструйовані поля, освітлення %s\n' ...
        '|Ex|: %s     |Ey|: %s'], labels{s}, U.rng(abs(Ex)), U.rng(abs(Ey))), ...
        'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','none','Color','k');
    R.figs{end+1} = U.save(fig, paths.steps, 2, sprintf('raw_field.%s', P), C);
end

% зведена таблиця масштабів по станах
fig = figure('Color','w','Visible','off','Position',[60 60 720 420]);
ax = axes(fig); bar(ax, [perState.mAbs]); grid(ax,'on');
set(ax,'XTickLabel',{perState.name},'FontName',C.fig.font,'FontSize',C.fig.fontSize, ...
       'XColor','k','YColor','k');
ylabel(ax, 'середнє |E| (Ex і Ey разом)', 'Color','k');
title(ax, sprintf('Крок 2. Масштаб амплітуди поля по станах — усюди ~10^{%d}', ...
      U.orderOf(allAbs)), 'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 2, 'raw_field.scale_by_state', C);

k = U.orderOf(allAbs);
R.lines{end+1} = sprintf(['Реконструйовані комплексні поля Ex, Ey мають амплітуду |E| ~ 10^{%d} ' ...
    '(медіана по ненульових пікселях, усі 6 станів). Це ДОВІЛЬНИЙ масштаб реконструкції ' ...
    '(нормування виконано поза цим кодом, при відновленні полів із голограм); фаза arg(E) — повний [-\\pi,\\pi].'], k);
if ~isempty(meta.zero)
    R.lines{end+1} = sprintf(['УВАГА: у цьому прикладі порожні (суцільний 0) канали: %s. ' ...
        'Це окремий дефект даних (див. крок 8), не повʼязаний із масштабом.'], strjoin(meta.zero, ', '));
end
R.budget{end+1} = struct('stage','вхід: сирі поля Ex, Ey', 'quantity','|E| амплітуда поля', ...
    'order',k, 'note','масштаб реконструкції (поза цим кодом)');
end
