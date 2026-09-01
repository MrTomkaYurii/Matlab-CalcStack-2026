function viz_phase_mask(deltaRef, mask, info, sampleLabel, CFG, outDir)
% VIZ_PHASE_MASK  Діагностична фігура фазового вікна (Етап 1 ТЗ): опорна
%   фаза delta_ref = angle(Ey)-angle(Ex) (освітлення CFG.phase.refPol) і
%   бінарна маска пікселів, що потрапили у вікно [0, U_k]. Дозволяє одразу
%   бачити, наскільки вузьке вікно "з'їдає" поле (важливо для QC — вузькі
%   вікна можуть лишити замало валідних пікселів).

S = viz_style();
fig = figure('Color','w','Visible','off','Position',[80 80 1300 560]);
S.light(fig);

N = size(deltaRef,1);
ax1 = subplot(1,2,1);
im = imagesc(ax1, 1:N, 1:N, deltaRef);
set(ax1,'YDir','normal'); axis(ax1,'image');
colormap(ax1, 'hsv'); caxis(ax1, [0 2*pi]);
cb = colorbar(ax1); cb.Label.String = '\delta_{ref} = arg(E_y) - arg(E_x)  (rad)';
cb.Ticks = [0 pi/2 pi 3*pi/2 2*pi];
cb.TickLabels = {'0','\pi/2','\pi','3\pi/2','2\pi'};
xlabel(ax1,'x (px)','FontSize',S.labelSize); ylabel(ax1,'y (px)','FontSize',S.labelSize);
title(ax1, sprintf('Reference phase (%s), window [0, %.2f\\pi]', CFG.phase.refPol, info.upper/pi), ...
      'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax1);

ax2 = subplot(1,2,2);
imagesc(ax2, 1:N, 1:N, double(mask));
set(ax2,'YDir','normal'); axis(ax2,'image');
colormap(ax2, [0.15 0.15 0.15; 0.95 0.85 0.20]);
caxis(ax2, [0 1]);
cb2 = colorbar(ax2, 'Ticks',[0.25 0.75], 'TickLabels',{'excluded','kept'});
xlabel(ax2,'x (px)','FontSize',S.labelSize); ylabel(ax2,'y (px)','FontSize',S.labelSize);
title(ax2, sprintf('Retained pixels: %.1f%% of %d', 100*info.keptFrac, numel(mask)), ...
      'FontSize',S.subSize,'FontWeight','bold');
S.apply(ax2);

sgtitle(sprintf('%s  \\cdot  phase window %d / %d', sampleLabel, info.index, CFG.phase.numWindows), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);

if ~exist(outDir,'dir'); mkdir(outDir); end
outFile = fullfile(outDir, ['phase_mask.' CFG.out.format]);
try
    exportgraphics(fig, outFile, 'Resolution', CFG.out.dpi);
catch
    print(fig, outFile, ['-d' CFG.out.format], sprintf('-r%d', CFG.out.dpi));
end
if CFG.out.closeAfter && ishandle(fig), close(fig); end
end
