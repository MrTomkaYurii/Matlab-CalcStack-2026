function tp_sim_preview(cfgOverride)
% TP_SIM_PREVIEW  Показати/зберегти «архітектоніку» симульованої тканини.
%   Малює карти орієнтації осі theta, затримки delta, амплітуди й фази спеклу,
%   а також 6 інтенсивностей для входу 0deg — щоб бачити, що дає симулятор.
%   Результати: <saveRoot>/<sample>/SIM_ANALYSIS/
%
%   Використання:  tp_sim_preview            (бере cfg_TwoPoint)
%                  tp_sim_preview(myCFG)

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(fullfile(root,'config'), fullfile(root,'core'), fullfile(root,'io'), ...
        fullfile(root,'viz'), fullfile(root,'simulation'));

if nargin >= 1 && isstruct(cfgOverride), CFG = cfgOverride; else, CFG = cfg_TwoPoint(); end
tp_check_config(CFG);   % рання перевірка конфігу

[IMG, SIM] = tp_sim_speckle_BT(CFG);
S = viz_style();
sample = CFG.samples{1};
outDir = fullfile(CFG.paths.saveRoot, sample, 'SIM_ANALYSIS');
if ~exist(outDir,'dir'), mkdir(outDir); end

% --- архітектоніка тканини ------------------------------------------
fig = figure('Color','w','Visible','off','Position',[60 60 1200 900]); S.light(fig);
mp(subplot(2,2,1), SIM.theta,       'Optical axis \theta (rad)',  'hsv',    S);
mp(subplot(2,2,2), SIM.delta,       'Retardance \delta (rad)',    'jet',    S);
mp(subplot(2,2,3), SIM.speckleAmp,  'Speckle amplitude |s|',      'jet',    S);
mp(subplot(2,2,4), SIM.specklePhase,'Speckle phase (rad)',        'hsv',    S);
sgtitle(sprintf('%s \\cdot simulated birefringent tissue (architectonics)', sample), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
saveFig(fig, outDir, 'sim_tissue');

% --- приклад: 6 інтенсивностей для входу 0deg -----------------------
an = {'I0','I45','I90','I135','Iliv','Iprav'};
fig = figure('Color','w','Visible','off','Position',[60 60 1400 800]); S.light(fig);
for a = 1:numel(an)
    mp(subplot(2,3,a), IMG.in0.(an{a}), an{a}, 'jet', S);
end
sgtitle(sprintf('%s \\cdot simulated intensities, input 0deg', sample), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
saveFig(fig, outDir, 'sim_intensities_in0');

fprintf('simulation preview -> %s\n', outDir);
end

% ------------------------------------------------------------------------
function mp(ax, Z, ttl, cmap, S)
imagesc(ax, Z); set(ax,'YDir','normal'); axis(ax,'image'); colormap(ax, cmap);
lo=min(Z(:)); hi=max(Z(:)); if lo<hi, caxis(ax,[lo hi]); end
cb=colorbar(ax); cb.Color=S.ink;
title(ax, sprintf('%s   [%.3g .. %.3g]', ttl, lo, hi), ...
      'FontSize',12,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

function saveFig(fig, outDir, name)
try, exportgraphics(fig, fullfile(outDir,[name '.png']),'Resolution',200);
catch, print(fig, fullfile(outDir,[name '.png']),'-dpng','-r200'); end
close(fig);
end
