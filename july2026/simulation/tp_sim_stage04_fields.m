function tp_sim_stage04_fields(DBG, outDir, S, sample)
% TP_SIM_STAGE04_FIELDS  Sim 04: вихідні поля Ex, Ey на кожне освітлення.
%   На кожен вхід (0,45,90,RC) — 2x2: |Ex|, arg(Ex), |Ey|, arg(Ey).
U = tp_test_util();
fprintf('\n-- Sim 04: output fields Ex, Ey per illumination --\n');
for p = 1:numel(DBG.pols)
    Pn = DBG.pols{p};  Ex = DBG.field.(Pn).Ex;  Ey = DBG.field.(Pn).Ey;
    fig = figure('Color','w','Visible','off','Position',[70 70 1150 900]); S.light(fig);
    U.panelMap(subplot(2,2,1), abs(Ex),   '|Ex|',        'jet', S);
    U.panelMap(subplot(2,2,2), angle(Ex), 'arg(Ex) (rad)','hsv', S);
    U.panelMap(subplot(2,2,3), abs(Ey),   '|Ey|',        'jet', S);
    U.panelMap(subplot(2,2,4), angle(Ey), 'arg(Ey) (rad)','hsv', S);
    sgtitle(sprintf('%s \\cdot Sim 04: output field after tissue+speckle [%s]', sample, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('sim04_field_%s', Pn));
    fprintf('   %-5s: |Ex| [%s]  |Ey| [%s]\n', Pn, U.rng(abs(Ex)), U.rng(abs(Ey)));
end
end
