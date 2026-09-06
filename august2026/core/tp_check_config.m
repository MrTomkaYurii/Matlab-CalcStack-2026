function tp_check_config(CFG)
% TP_CHECK_CONFIG  Перевірка коректності CFG на старті (fail-fast із ясним текстом).
%   Викликається лаунчерами одразу після побудови CFG, ЩОБ помилки конфігу
%   ловилися рано й зрозуміло, а не десь глибоко в розрахунку.

tp_assert(isfield(CFG,'crop') && isfield(CFG.crop,'size') && CFG.crop.size >= 2, ...
    'CFG.crop.size має бути цілим >= 2');
tp_assert(ischar(CFG.source) && any(strcmpi(CFG.source,{'synthetic','real','mat'})), ...
    'CFG.source має бути ''synthetic'', ''real'' або ''mat'' (зараз: %s)', string(CFG.source));
tp_assert(iscell(CFG.samples)  && ~isempty(CFG.samples),  'CFG.samples: непорожній cell-масив імен');
tp_assert(iscell(CFG.elements) && ~isempty(CFG.elements), 'CFG.elements: непорожній cell-масив (напр. {''f11''})');
tp_assert(iscell(CFG.algorithms) && ~isempty(CFG.algorithms), 'CFG.algorithms: непорожній cell-масив');
tp_assert(all(ismember(lower(CFG.algorithms), {'orthogonal','generalized','polar'})), ...
    'CFG.algorithms: підмножина {''orthogonal'',''generalized'',''polar''}');

if isfield(CFG,'ortho')
    tp_assert(isnumeric(CFG.ortho.steps) && ~isempty(CFG.ortho.steps) ...
        && all(CFG.ortho.steps >= 1) && all(CFG.ortho.steps == round(CFG.ortho.steps)), ...
        'CFG.ortho.steps: додатні цілі рознесення (напр. [1 2 4 8 16])');
    if isfield(CFG.ortho,'posStep')
        tp_assert(CFG.ortho.posStep >= 1, 'CFG.ortho.posStep (прорідження перших точок) має бути >= 1');
    end
    if isfield(CFG.ortho,'directions')
        tp_assert(iscell(CFG.ortho.directions) && ~isempty(CFG.ortho.directions) ...
            && all(ismember(upper(CFG.ortho.directions), {'OX','OY'})), ...
            'CFG.ortho.directions: підмножина {''OX'',''OY''} (напр. {''OY''})');
    end
end

if isfield(CFG,'polar')
    tp_assert(isnumeric(CFG.polar.radii) && ~isempty(CFG.polar.radii) ...
        && all(CFG.polar.radii >= 1) && all(CFG.polar.radii == round(CFG.polar.radii)), ...
        'CFG.polar.radii: додатні цілі рознесення rho (напр. [1] або [1 2 4])');
    tp_assert(isnumeric(CFG.polar.angleStep) && CFG.polar.angleStep > 0 && CFG.polar.angleStep <= 180, ...
        'CFG.polar.angleStep: крок кута в градусах, (0, 180]');
    tp_assert(isnumeric(CFG.polar.angleMax) && CFG.polar.angleMax > 0 && CFG.polar.angleMax <= 360, ...
        'CFG.polar.angleMax: діапазон кутів у градусах, (0, 360]');
    if isfield(CFG.polar,'posStep')
        tp_assert(CFG.polar.posStep >= 1, 'CFG.polar.posStep має бути >= 1');
    end
    if isfield(CFG.polar,'montageElements')
        tp_assert(iscell(CFG.polar.montageElements), 'CFG.polar.montageElements: cell-масив імен f_ik');
    end
end

tp_assert(isfield(CFG,'viz') && iscell(CFG.viz.colormaps) && ~isempty(CFG.viz.colormaps), ...
    'CFG.viz.colormaps: непорожній cell-масив (напр. {''jet'',''gray''})');
if isfield(CFG.viz,'contourSmoothPx')
    tp_assert(CFG.viz.contourSmoothPx >= 0, 'CFG.viz.contourSmoothPx має бути >= 0 (0 = вимкнено)');
end
if isfield(CFG.viz,'bandLevels')
    tp_assert(CFG.viz.bandLevels >= 2 && CFG.viz.bandLevels == round(CFG.viz.bandLevels), ...
        'CFG.viz.bandLevels має бути цілим >= 2');
end
if isfield(CFG.viz,'bandWidthPct')
    tp_assert(CFG.viz.bandWidthPct > 0 && CFG.viz.bandWidthPct < 1, ...
        'CFG.viz.bandWidthPct має бути в (0,1) (напр. 0.02 = 2%%)');
end

if isfield(CFG,'gen')
    tp_assert(isnumeric(CFG.gen.steps) && ~isempty(CFG.gen.steps) && all(CFG.gen.steps >= 1), ...
        'CFG.gen.steps: масив додатних кроків (напр. [1 2 4 8 16])');
    tp_assert(CFG.gen.posStep  >= 1, 'CFG.gen.posStep має бути >= 1');
    tp_assert(isempty(CFG.gen.maxDist) || CFG.gen.maxDist >= 1, 'CFG.gen.maxDist: [] або >= 1');
end

if strcmpi(CFG.source, 'real')
    % examples МОЖЕ бути порожнім (нова структура: тека зразка = повний
    % шлях, без підтек zrazok_1/zrazok_2) — вимагаємо лише щоб поле було
    % валідним cell-масивом (порожнім чи ні).
    tp_assert(isfield(CFG.paths,'examples') && iscell(CFG.paths.examples), ...
        'CFG.paths.examples має бути cell-масивом (можна порожнім {} — без підтек)');
    tp_assert(exist(CFG.paths.readRoot,'dir') == 7, 'CFG.paths.readRoot не знайдено: %s', CFG.paths.readRoot);
end

if isfield(CFG,'phase') && isfield(CFG.phase,'enable') && CFG.phase.enable
    tp_assert(CFG.phase.numWindows >= 1 && CFG.phase.numWindows == round(CFG.phase.numWindows), ...
        'CFG.phase.numWindows має бути цілим >= 1');
    tp_assert(CFG.phase.upperMax > CFG.phase.upperMin && CFG.phase.upperMin > 0, ...
        'CFG.phase.upperMax має бути > CFG.phase.upperMin > 0');
    tp_assert(ischar(CFG.phase.refPol) && ~isempty(CFG.phase.refPol), ...
        'CFG.phase.refPol: непорожній рядок (напр. ''inRC'')');
end

if isfield(CFG,'multifractal') && isfield(CFG.multifractal,'qRange')
    tp_assert(isnumeric(CFG.multifractal.qRange) && numel(CFG.multifractal.qRange) >= 3, ...
        'CFG.multifractal.qRange: числовий масив з >= 3 значень (напр. -5:0.5:5)');
end

if strcmpi(CFG.source, 'mat')
    tp_assert(isfield(CFG,'paths') && isfield(CFG.paths,'matRoot'), ...
        'CFG.paths.matRoot відсутній (потрібен для source=mat)');
    tp_assert(exist(CFG.paths.matRoot,'dir') == 7, ...
        'CFG.paths.matRoot не знайдено: %s', CFG.paths.matRoot);
    if isfield(CFG.paths,'examples')
        tp_assert(iscell(CFG.paths.examples), ...
            'CFG.paths.examples має бути cell-масивом (можна порожнім {} — без підтек)');
    end
    if isfield(CFG,'mat') && isfield(CFG.mat,'rcSource')
        tp_assert(ismember(lower(CFG.mat.rcSource), {'liv','prav'}), ...
            'CFG.mat.rcSource має бути ''liv'' або ''prav''');
    end
end

if strcmpi(CFG.source, 'synthetic')
    tp_assert(isfield(CFG,'sim'), 'CFG.sim відсутній (потрібен для source=synthetic)');
    tp_assert(CFG.sim.axisCorrLen > 0 && CFG.sim.retCorrLen > 0 && CFG.sim.speckleCorrLen > 0, ...
        'CFG.sim.*CorrLen мають бути > 0');
    tp_assert(CFG.sim.retMax >= CFG.sim.retMin, 'CFG.sim.retMax має бути >= CFG.sim.retMin');
end
end
