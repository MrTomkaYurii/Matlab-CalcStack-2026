function viz_analytics_overview(allS, catalog, outFile)
% VIZ_ANALYTICS_OVERVIEW  Одна зведена картинка-"зміст": рядки = 22
%   метрики (згруповані статистика/кореляція/фрактал), стовпці = 16
%   елементів f_ik, колір клітинки = позначка (тренд/розрізняє/обидва/
%   нічого) — щоб одним поглядом бачити, куди йти в деталізацію.
%
%   allS : struct з полями = імена метрик, значення = вихід
%          tp_analytics_build_series для цієї метрики
%   catalog : tp_analytics_metric_catalog()

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

elements = fieldnames(allS.(rows{1}).badge);
elements = sort(elements);
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

Sty = viz_style();   % примусово світла тема — інакше нечитабельно в темній темі MATLAB
fig = figure('Color','w','Visible','off','Position',[40 40 1300 1400]);
Sty.light(fig);
cmap = [0.90 0.90 0.90; 0.20 0.60 0.20; 0.85 0.45 0.05; 0.75 0.60 0.05];
imagesc(code, [0 3]); colormap(fig, cmap);
Sty.apply(gca);
set(gca, 'XTick', 1:nC, 'XTickLabel', elements, 'XAxisLocation','top', 'FontSize', 8, 'TickLabelInterpreter','none');
set(gca, 'YTick', 1:nR, 'YTickLabel', rowLabels, 'FontSize', 7.5, 'TickLabelInterpreter','none');
grid(gca, 'off');
xlabel('Елемент f_{ik}', 'FontSize', 10, 'Interpreter','tex');
title({'Огляд знайдених закономірностей — де саме дивитись', ...
       'сірий = нічого, зелений = тренд по фазовому вікну, ' , ...
       'оранжевий = розрізняє зразки, золотий = обидва'}, 'FontSize', 10);

for r = 1:nR
    for c = 1:nC
        if code(r,c) > 0
            text(c, r, char(9679), 'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                 'FontSize', 8, 'Color', 'k');
        end
    end
end

axis(gca, 'image');
outDir = fileparts(outFile);
if ~exist(outDir,'dir'); mkdir(outDir); end
exportgraphics(fig, outFile, 'Resolution', 150);
close(fig);
end
