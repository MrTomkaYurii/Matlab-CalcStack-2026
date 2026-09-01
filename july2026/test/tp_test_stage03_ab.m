function tp_test_stage03_ab(DBG, outDir, S, cmap, P)
% TP_TEST_STAGE03_AB  Stage 03: проміжні реальні складові a_i, b_i (i=1..4).
%   На кожне освітлення — сітка 2x4: верх a1..a4, низ b1..b4 (з діапазонами).
U = tp_test_util();
fprintf('\n-- Stage 03: intermediate real components a_i, b_i --\n');
for p = 1:numel(DBG.pols)
    Pn = DBG.pols{p};
    fig = figure('Color','w','Visible','off','Position',[40 40 1600 820]); S.light(fig);
    for i = 1:4
        U.panelMap(subplot(2,4,i),   DBG.a{i}.(Pn), sprintf('a_%d', i), cmap, S);
        U.panelMap(subplot(2,4,i+4), DBG.b{i}.(Pn), sprintf('b_%d', i), cmap, S);
    end
    sgtitle(sprintf('%s \\cdot %s \\cdot Stage 03: a_i, b_i [%s]', P.sample, P.direction, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('stage03_ab_%s', Pn));
    fprintf('   %-5s: a1 [%s]  b1 [%s]\n', Pn, U.rng(DBG.a{1}.(Pn)), U.rng(DBG.b{1}.(Pn)));
end
end
