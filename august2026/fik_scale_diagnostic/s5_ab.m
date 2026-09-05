function R = s5_ab(C, paths, U, DBG)
% S5_AB  Крок 5 — проміжні дійсні складові a_i, b_i (i=1..4) для 4 освітлень.
%   САМЕ ТУТ зʼявляється множник ~1e-6: кожен доданок a_i / b_i — це ДОБУТОК
%   ДВОХ амплітуд поля (Ex1·Ex2, Ey1·Ey2·cos(dd), Ex1·Ey2·cos(d2) …).
%   (~1e-3) · (~1e-3) = ~1e-6.
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

pols = DBG.pols;                 % {'in0','in45','in90','inRC'}
polLab = {'0°','45°','90°','RC'};
a = DBG.a;  b = DBG.b;           % a{i}.(P), b{i}.(P)

allAB = [];
for p = 1:numel(pols)
    P = pols{p};
    fig = figure('Color','w','Visible','off','Position',[40 40 1250 900]);
    for i = 1:4
        Ai = a{i}.(P);  Bi = b{i}.(P);
        allAB = [allAB; Ai(isfinite(Ai)); Bi(isfinite(Bi))]; %#ok<AGROW>
        U.panel(subplot(4,2,2*i-1), Ai, sprintf('a_%d  (%s)', i, polLab{p}), C.fig.cmapMod, C);
        U.panel(subplot(4,2,2*i  ), Bi, sprintf('b_%d  (%s)', i, polLab{p}), C.fig.cmapMod, C);
    end
    sgtitle(sprintf(['Крок 5. Проміжні складові a_i, b_i, освітлення %s\n' ...
        'кожна — сума ДОБУТКІВ двох амплітуд (~10^{-3})·(~10^{-3}) -> ~10^{-6}'], polLab{p}), ...
        'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
    R.figs{end+1} = U.save(fig, paths.steps, 5, sprintf('ab.%s', P), C);
end

% формульна довідка (текстова панель)
fig = figure('Color','w','Visible','off','Position',[60 60 900 460]);
ax = axes(fig,'Position',[0 0 1 1]);  axis(ax,'off');
txt = {
 'Крок 5. Звідки береться квадрат масштабу — формули (6)–(13):'
 ''
 '   a_1 = Ex_1·Ex_2 + Ey_1·Ey_2·cos(\delta\delta)'
 '   b_1 = Ey_1·Ey_2·sin(\delta\delta)'
 '   a_3 = Ex_1·Ey_2·cos(\delta_2) + Ex_2·Ey_1·cos(\delta_1)'
 '   b_3 = Ex_1·Ey_2·sin(\delta_2) − Ex_2·Ey_1·sin(\delta_1)'
 '        … і т.д. для i = 2, 4'
 ''
 'КОЖЕН доданок = (амплітуда)·(амплітуда). Тому:'
 '   |E| ~ 10^{-3}   =>   a_i, b_i ~ 10^{-6}'
 ''
 'Тригонометричні множники cos/sin — порядку одиниці, масштаб не міняють.'
 };
text(ax, 0.04, 0.95, txt, 'VerticalAlignment','top', 'FontName',C.fig.font, ...
     'FontSize',C.fig.fontSize+1, 'Interpreter','tex', 'Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 5, 'ab.formula_note', C);

k = U.orderOf(allAB);
R.lines{end+1} = sprintf(['Проміжні a_i, b_i ~ 10^{%d}. Це і є момент появи "малості": ' ...
    'формули (6)–(13) БІЛІНІЙНІ за полем — кожен доданок це добуток двох амплітуд ' ...
    '(~10^{-3})·(~10^{-3}). Тригонометрія (cos\\delta, sin\\delta\\delta) масштаб не змінює.'], k);
R.budget{end+1} = struct('stage','a_i, b_i  (формули 6–13)', 'quantity','дійсні складові', ...
    'order',k, 'note','ДОБУТОК двох амплітуд -> (масштаб поля)^2');
end
