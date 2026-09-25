function tp_sim_stage05_intensities(DBG, outDir, S, sample)
% TP_SIM_STAGE05_INTENSITIES  Sim 05: інтенсивності на кожне освітлення.
%   На кожен вхід -- 2x3: I0, I45, I90, I135, Iliv, Iprav.
%   АДАПТАЦІЯ: у july2026 етап отримував готові інтенсивності (IMG); тепер
%   генератор віддає комплексні поля, тож інтенсивності рахуються тут
%   (tp_sim_intensities.m -- ті самі формули) зі СПІЛЬНИМ нормуванням
%   (один множник на всі канали й освітлення, як у july2026) -- лише для показу.
U = tp_sim_util();
fprintf('\n-- Sim 05: formed intensities per illumination --\n');
an = {'I0','I45','I90','I135','Iliv','Iprav'};

Iall = struct();  gmax = 0;
for p = 1:numel(DBG.pols)
    Pn = DBG.pols{p};
    Iall.(Pn) = tp_sim_intensities(DBG.field.(Pn).Ex, DBG.field.(Pn).Ey);
    for a = 1:numel(an), gmax = max(gmax, max(Iall.(Pn).(an{a})(:))); end
end

for p = 1:numel(DBG.pols)
    Pn = DBG.pols{p};
    fig = figure('Color','w','Visible','off','Position',[60 60 1400 800]); S.light(fig);
    for a = 1:numel(an)
        U.panelMap(subplot(2,3,a), Iall.(Pn).(an{a}) / (gmax + eps), an{a}, 'jet', S);
    end
    sgtitle(sprintf('%s \\cdot Sim 05: formed intensities [%s]', sample, Pn), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    U.saveFig(fig, outDir, sprintf('sim05_intensities_%s', Pn));
end
end
