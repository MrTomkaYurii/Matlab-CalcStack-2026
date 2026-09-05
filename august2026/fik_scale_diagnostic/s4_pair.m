function [R, DBG, F] = s4_pair(C, paths, U, IMG)
% S4_PAIR  Крок 4 — двоточковий зріз: те, що реально заходить у tp_fik_pair.
%   Для обраного напряму й відстані d: амплітуди |Ex1|,|Ey1| та фаза
%   delta1 = arg(Ey1)-arg(Ex1) у точці 1; те саме в точці 2; та dd = d2-d1.
%   Тут ще НЕ множимо — величини лишаються ~1e-3 (амплітуди) і ~1 (фази).
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

[A1, A2] = U.pair(IMG, C.pairDir, C.pairDist);
[F, DBG] = tp_fik_pair(A1, A2);            % DBG.perPol.(P).Ex1/Ex2/Ey1/Ey2/d1/d2

P = 'in0';  Q = DBG.perPol.(P);
dd = Q.d2 - Q.d1;

fig = figure('Color','w','Visible','off','Position',[50 50 1220 760]);
U.panel(subplot(2,3,1), Q.Ex1, '|Ex| точка 1',            C.fig.cmapMod, C);
U.panel(subplot(2,3,2), Q.Ey1, '|Ey| точка 1',            C.fig.cmapMod, C);
U.panel(subplot(2,3,3), Q.d1,  '\delta_1 = arg(Ey_1)-arg(Ex_1)', C.fig.cmapArg, C);
U.panel(subplot(2,3,4), Q.Ex2, '|Ex| точка 2',            C.fig.cmapMod, C);
U.panel(subplot(2,3,5), Q.Ey2, '|Ey| точка 2',            C.fig.cmapMod, C);
U.panel(subplot(2,3,6), dd,    '\delta\delta = \delta_2-\delta_1', C.fig.cmapArg, C);
sgtitle(sprintf(['Крок 4. Двоточковий зріз (%s, d = %d px), освітлення %s\n' ...
    'амплітуди |E| ~ %s (масштаб не змінився);  фази \\delta ~ [-\\pi,\\pi]'], ...
    C.pairDir, C.pairDist, P, U.eng(mean(abs([Q.Ex1(:);Q.Ey1(:)]),'omitnan'))), ...
    'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 4, sprintf('pair_slice.%s', P), C);

kA = U.orderOf([Q.Ex1(:);Q.Ey1(:)]);
R.lines{end+1} = sprintf(['У tp_fik_pair заходять: амплітуди |Ex|,|Ey| ~ 10^{%d} (той самий масштаб, ' ...
    'що й на кроці 2) і різницеві фази \\delta порядку одиниці. Множення ще не відбулось.'], kA);
R.budget{end+1} = struct('stage','вхід у формулу f_{ik} (пара точок)', 'quantity','|Ex|,|Ey| у точках 1,2', ...
    'order',kA, 'note','масштаб той самий; фази O(1)');
end
