function tp_sim_stage01_tissue(SIM, outDir, S, sample)
% TP_SIM_STAGE01_TISSUE  Sim 01: архітектоніка — орієнтація осі та двопроменезаломлення.
%   Панелі: [ theta (карта) | delta (карта) ; orientation quiver | delta histogram ].
U = tp_test_util();
fprintf('\n-- Sim 01: tissue architectonics (axis orientation, birefringence) --\n');
N = size(SIM.theta,1);

fig = figure('Color','w','Visible','off','Position',[60 60 1250 950]); S.light(fig);

U.panelMap(subplot(2,2,1), SIM.theta, 'Optical axis \theta (rad)', 'hsv', S);
U.panelMap(subplot(2,2,2), SIM.delta, 'Retardance \delta (rad, birefringence)', 'jet', S);

% орієнтація осі як штрихи (quiver без стрілок)
ax = subplot(2,2,3);
imagesc(ax, SIM.theta); set(ax,'YDir','normal'); axis(ax,'image'); colormap(ax,'hsv');
colorbar(ax); hold(ax,'on');
st = max(1, round(N/25)); [X,Y] = meshgrid(1:st:N, 1:st:N);
th = SIM.theta(1:st:N, 1:st:N); u = cos(th); v = sin(th);
quiver(ax, X-u/2, Y-v/2, u, v, 0.5, 'k', 'ShowArrowHead','off', 'LineWidth',1);
title(ax,'Optical axis orientation (director field)','FontSize',S.subSize,'FontWeight','bold');
S.apply(ax);

ax = subplot(2,2,4);
histogram(ax, SIM.delta(:), 50, 'FaceColor',[0.2 0.4 0.8], 'EdgeColor',[0.2 0.2 0.2]);
xlabel(ax,'\delta (rad)','FontSize',S.labelSize); ylabel(ax,'count','FontSize',S.labelSize);
title(ax,'Retardance distribution','FontSize',S.subSize,'FontWeight','bold'); S.apply(ax);

sgtitle(sprintf('%s \\cdot Sim 01: tissue architectonics (axes & birefringence)', sample), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
U.saveFig(fig, outDir, 'sim01_tissue');
fprintf('   theta [%s] rad | delta [%s] rad\n', U.rng(SIM.theta), U.rng(SIM.delta));
end
