function tp_sim_stage05_intensities(IMG, outDir, S, sample)
% TP_SIM_STAGE05_INTENSITIES  Sim 05: сформовані інтенсивності на кожне освітлення.
%   На кожен вхід — 2x3: I0, I45, I90, I135, Iliv, Iprav (те, що йде на вхід f_ik).
U = tp_test_util();
fprintf('\n-- Sim 05: formed intensities per illumination --\n');
an = {'I0','I45','I90','I135','Iliv','Iprav'};
pols = fieldnames(IMG);
for p = 1:numel(pols)
    Pn = pols{p};
    fig = figure('Color','w','Visible','off','Position',[60 60 1400 800]); S.light(fig);
    for a = 1:numel(an)
        U.panelMap(subplot(2,3,a), IMG.(Pn).(an{a}), an{a}, 'jet', S);
    end
    sgtitle(sprintf('%s \\cdot Sim 05: formed intensities [%s]', sample, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('sim05_intensities_%s', Pn));
end
end
