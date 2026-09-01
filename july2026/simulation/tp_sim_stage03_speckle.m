function tp_sim_stage03_speckle(SIM, outDir, S, sample)
% TP_SIM_STAGE03_SPECKLE  Sim 03: когерентний спекл-носій.
%   Панелі: [ |s| амплітуда | фаза s | інтенсивність |s|^2 ].
U = tp_test_util();
fprintf('\n-- Sim 03: coherent speckle carrier --\n');

fig = figure('Color','w','Visible','off','Position',[60 60 1500 480]); S.light(fig);
U.panelMap(subplot(1,3,1), SIM.speckleAmp,        'Speckle amplitude |s|',    'jet', S);
U.panelMap(subplot(1,3,2), SIM.specklePhase,      'Speckle phase (rad)',      'hsv', S);
U.panelMap(subplot(1,3,3), SIM.speckleAmp.^2,     'Speckle intensity |s|^2',  'jet', S);
sgtitle(sprintf('%s \\cdot Sim 03: coherent speckle carrier', sample), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
U.saveFig(fig, outDir, 'sim03_speckle');
fprintf('   |s| [%s]\n', U.rng(SIM.speckleAmp));
end
