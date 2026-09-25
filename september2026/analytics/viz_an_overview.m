function viz_an_overview(allS, catalog, outFile, Sty)
% VIZ_AN_OVERVIEW  Одна зведена картинка-"зміст": рядки = 22 метрики (згруповані
%   статистика/кореляція/фрактал), стовпці = 5 величин Кроку B, колір клітинки =
%   позначка (тренд / розрізняє / обидва / нічого) -- одним поглядом видно, куди
%   йти в деталізацію. ПОРТ серпневого viz_analytics_overview.m (там 16 f_ik).
%
%   allS    : struct, поля = імена метрик, значення = вихід tp_an_build_series
%   catalog : tp_an_metric_catalog()
%   Sty     : viz_style(CFG.style)

groups = {'statistics','correlation','fractal'};
groupLabel = struct('statistics','Статистика', 'correlation','Кореляція (АКФ)', 'fractal','Фрактал');

rows = {}; rowLabels = {};
for g = 1:numel(groups)
    grp = groups{g};
    entries = catalog.(grp);
    for e = 1:numel(entries)
        rows{end+1} = entries{e}{1}; %#ok<AGROW>
        rowLabels{end+1} = sprintf('[%s] %s', groupLabel.(grp), entries{e}{2}); %#ok<AGROW>
    end
end

elements = allS.(rows{1}).elements;          % порядок величин Кроку B
nR = numel(rows); nC = numel(elements);

code = zeros(nR, nC);   % 0=none,1=trend,2=discrim,3=both
codeMap = struct('none',0, 'trend',1, 'discrim',2, 'both',3);
for r = 1:nR
    S = allS.(rows{r});
    for c = 1:nC
        elem = elements{c};
        if isfield(S.badge, elem)
            code(r,c) = codeMap.(S.badge.(elem));
        end
    end
end

fig = figure('Color','w','Visible','off','Position',[40 40 1000 1300]);
Sty.light(fig);
cmap = [0.90 0.90 0.90; 0.20 0.60 0.20; 0.85 0.45 0.05; 0.75 0.60 0.05];
imagesc(code, [0 3]); colormap(fig, cmap);
Sty.apply(gca);
xt = cellfun(@tp_an_elem_tex, elements, 'UniformOutput', false);
% TickLabelInterpreter -- властивість УСІХ осей разом (не окремо X/Y), тож 'tex' для обох:
% підписи стовпців (LB_{0,90}, \rho) і рядків (\Deltah у метриці мультифракталу)
set(gca, 'XTick', 1:nC, 'XTickLabel', xt, 'XAxisLocation','top', 'FontSize', 10);
set(gca, 'YTick', 1:nR, 'YTickLabel', rowLabels, 'FontSize', 8);
set(gca, 'TickLabelInterpreter', 'tex');
grid(gca, 'off');
xlabel('Величина Кроку B', 'FontSize', 10);
title({'Огляд знайдених закономірностей — де саме дивитись', ...
       'сірий = нічого, зелений = тренд по фазовому вікну, ', ...
       'оранжевий = розрізняє зразки, золотий = обидва'}, 'FontSize', 10);

for r = 1:nR
    for c = 1:nC
        if code(r,c) > 0
            text(c, r, char(9679), 'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                 'FontSize', 9, 'Color', 'k');
        end
    end
end

axis(gca, 'image');
outDir = fileparts(outFile);
if ~exist(outDir,'dir'); mkdir(outDir); end
try
    exportgraphics(fig, outFile, 'Resolution', 150, 'Padding', 'figure');
catch
    exportgraphics(fig, outFile, 'Resolution', 150);
end
close(fig);
end
