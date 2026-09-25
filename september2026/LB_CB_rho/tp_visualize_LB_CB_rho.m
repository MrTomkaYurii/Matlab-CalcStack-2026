function tp_visualize_LB_CB_rho(R2, dir, CFG)
% TP_VISUALIZE_LB_CB_RHO  Візуалізація Кроку B: для кожного з 5 елементів
%   (LB_0_90, LB_45_135, CB, rho, LB) — ТІ САМІ подання, що раніше для
%   f_ik (tp_visualize.m), усі, не лише карти+контури:
%     (1)  2x2 карти модуля/аргументу + гістограми     — viz_maps_hist.m
%     Блок1 карти->гістограми->АКФ ОДНІЄЮ фігурою      — viz_block1_summary.m
%     (2)  2x2 3D-поверхні + контурні карти             — viz_sections.m
%     (2b) контурні лінії у 3D (contour3)                — viz_contour3d.m
%     Блок3 2D контур + 3D контур ОДНІЄЮ фігурою         — viz_block3_contours.m
%     Блок4 спектр f(h) з WTMM                           — viz_multifractal.m
%           + D(q), τ(q)                                 — viz_multifractal_dimensions.m
%     (3)  вейвлет W(a,b) (мод+арг)                       — viz_wavelet.m
%     (4A) 2D АКФ + 2D PSD (мод+арг)                      — viz_acf_psd.m
%     (4B) 1D перерізи ACF + їх PSD (log-log)              — viz_acf_cuts.m
%     (5)  вейвлет-скелетон + гістограма максимумів        — viz_skeleton.m
%     (6)  смуговий аналіз концентрації біля рівнів         — viz_level_bands.m
%   Статистика (текстові файли по теках елементів) -- ОКРЕМО:
%   tp_stats_LB_CB_rho.m (CFG.stepB.stats).
%
%   R2  : вихід tp_LB_CB_rho_from_result.m (R2.elements = 5 нових імен)
%   dir : той самий напрям/крок, що передавався туди
%   CFG : cfg_September() (поля .viz [перемикачі й параметри], .out, .qc,
%         .acf, .wavelet, .multifractal, .style, .paths.saveRoot)

for e = 1:numel(R2.elements)
    elem = R2.elements{e};
    % CFG.viz.elements (cfg_September.m): які з п'яти малювати; немає поля => усі
    if isfield(CFG.viz,'elements') && ~any(strcmp(CFG.viz.elements, elem)), continue; end
    D = R2.data.(dir).(elem);

    [ok, reason] = tp_validate(D.mod, CFG);
    if ~ok
        fprintf('   [skip] %s/%s/%s: %s\n', R2.algorithm, dir, elem, reason);
        continue;
    end

    [meta, ctx] = tp_element_meta(R2, dir, elem, CFG);   % підписи, осі, АКФ, шлях
    tag = sprintf('%s/%s/%s', R2.algorithm, dir, elem);

    % Перемикачі CFG.viz.<ім'я> (cfg_September.m, розділ 6): відсутній => увімкнено.
    if isOn(CFG,'mapsHist'),      runViz(@viz_maps_hist,               D, meta, ctx, CFG, tag, 'maps_hist'); end
    if isOn(CFG,'blockSummary'),  runViz(@viz_block1_summary,          D, meta, ctx, CFG, tag, 'block1_summary'); end
    if isOn(CFG,'surfContour'),   runViz(@viz_sections,                D, meta, ctx, CFG, tag, 'surf_contour'); end
    if isOn(CFG,'contour3'),      runViz(@viz_contour3d,               D, meta, ctx, CFG, tag, 'contour3'); end
    if isOn(CFG,'blockContours'), runViz(@viz_block3_contours,         D, meta, ctx, CFG, tag, 'block3_contours'); end
    if isOn(CFG,'multifractal')
        runViz(@viz_multifractal,            D, meta, ctx, CFG, tag, 'multifractal');
        runViz(@viz_multifractal_dimensions, D, meta, ctx, CFG, tag, 'multifractal_dims');
    end
    if isOn(CFG,'wavelet'),       runViz(@viz_wavelet,                 D, meta, ctx, CFG, tag, 'wavelet'); end
    if isOn(CFG,'acfPsd'),        runViz(@viz_acf_psd,                 D, meta, ctx, CFG, tag, 'acf_psd'); end
    if isOn(CFG,'acfCuts'),       runViz(@viz_acf_cuts,                D, meta, ctx, CFG, tag, 'acf_cuts'); end
    if isOn(CFG,'skeleton'),      runViz(@viz_skeleton,                D, meta, ctx, CFG, tag, 'skeleton'); end
    if isOn(CFG,'levelBands'),    runViz(@viz_level_bands,             D, meta, ctx, CFG, tag, 'level_bands'); end
end
end

% ------------------------------------------------------------------------
function tf = isOn(CFG, name)
% Перемикач подання: CFG.viz.<name>; якщо поля немає -- увімкнено.
tf = ~isfield(CFG.viz, name) || logical(CFG.viz.(name));
end

% ------------------------------------------------------------------------
function runViz(fn, D, meta, ctx, CFG, tag, name)
% Виклик модуля візуалізації з обробкою помилок: збій одного рисунка
% логується і НЕ валить решту (та сама політика, що й tp_visualize.m).
try
    fn(D, meta, ctx, CFG);
catch ME
    fprintf(2, '   [viz fail] %s %s: %s\n', tag, name, ME.message);
end
end
