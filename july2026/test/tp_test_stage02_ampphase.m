function tp_test_stage02_ampphase(DBG, outDir, S, cmap, P)
% TP_TEST_STAGE02_AMPPHASE  Stage 02: амплітуди Ex,Ey та фаза delta (точки 1,2).
U = tp_test_util();
fprintf('\n-- Stage 02: amplitudes Ex,Ey and phase delta --\n');
for p = 1:numel(DBG.pols)
    Pn = DBG.pols{p};  g = DBG.perPol.(Pn);
    fig = figure('Color','w','Visible','off','Position',[60 60 1400 800]); S.light(fig);
    U.panelMap(subplot(2,3,1), g.Ex1, '|Ex| point 1 = sqrt(I0)',  cmap, S);
    U.panelMap(subplot(2,3,2), g.Ey1, '|Ey| point 1 = sqrt(I90)', cmap, S);
    U.panelMap(subplot(2,3,3), g.d1,  '\delta point 1 (rad)',     cmap, S);
    U.panelMap(subplot(2,3,4), g.Ex2, '|Ex| point 2',             cmap, S);
    U.panelMap(subplot(2,3,5), g.Ey2, '|Ey| point 2',             cmap, S);
    U.panelMap(subplot(2,3,6), g.d2,  '\delta point 2 (rad)',     cmap, S);
    sgtitle(sprintf('%s \\cdot %s \\cdot Stage 02: amplitudes & phase [%s]', P.sample, P.direction, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('stage02_amp_phase_%s', Pn));
    fprintf('   %-5s: Ex1 [%s]  d1 [%s]\n', Pn, U.rng(g.Ex1), U.rng(g.d1));
end
end
