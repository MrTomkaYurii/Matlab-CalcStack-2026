function tp_test_stage01_inputs(IMG, outDir, S, cmap, P)
% TP_TEST_STAGE01_INPUTS  Stage 01: вхідні поляризаційні зображення.
%   На кожне освітлення — сітка 2x3 з I0,I45,I90,I135,Iliv,Iprav (з діапазонами).
U = tp_test_util();
fprintf('\n-- Stage 01: input polarization images --\n');
an = {'I0','I45','I90','I135','Iliv','Iprav'};
pols = fieldnames(IMG);
for p = 1:numel(pols)
    Pn = pols{p};
    fig = figure('Color','w','Visible','off','Position',[60 60 1400 800]); S.light(fig);
    for a = 1:numel(an)
        U.panelMap(subplot(2,3,a), IMG.(Pn).(an{a}), an{a}, cmap, S);
    end
    sgtitle(sprintf('%s \\cdot %s \\cdot Stage 01: input images [%s]', P.sample, P.direction, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('stage01_input_%s', Pn));
    fprintf('   %-5s: I0 [%s]  I90 [%s]\n', Pn, U.rng(IMG.(Pn).I0), U.rng(IMG.(Pn).I90));
end
end
