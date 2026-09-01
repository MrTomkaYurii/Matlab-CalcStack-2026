function tp_check_config(CFG)
% TP_CHECK_CONFIG  Перевірка коректності CFG на старті (fail-fast із ясним текстом).
%   Викликається лаунчерами одразу після побудови CFG, ЩОБ помилки конфігу
%   ловилися рано й зрозуміло, а не десь глибоко в розрахунку.

tp_assert(isfield(CFG,'crop') && isfield(CFG.crop,'size') && CFG.crop.size >= 2, ...
    'CFG.crop.size має бути цілим >= 2');
tp_assert(ischar(CFG.source) && any(strcmpi(CFG.source,{'synthetic','real'})), ...
    'CFG.source має бути ''synthetic'' або ''real'' (зараз: %s)', string(CFG.source));
tp_assert(iscell(CFG.samples)  && ~isempty(CFG.samples),  'CFG.samples: непорожній cell-масив імен');
tp_assert(iscell(CFG.elements) && ~isempty(CFG.elements), 'CFG.elements: непорожній cell-масив (напр. {''f11''})');
tp_assert(iscell(CFG.algorithms) && ~isempty(CFG.algorithms), 'CFG.algorithms: непорожній cell-масив');

tp_assert(isfield(CFG,'ortho') && isnumeric(CFG.ortho.steps) && ~isempty(CFG.ortho.steps) ...
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

if strcmpi(CFG.source, 'synthetic')
    tp_assert(isfield(CFG,'sim'), 'CFG.sim відсутній (потрібен для source=synthetic)');
    tp_assert(CFG.sim.axisCorrLen > 0 && CFG.sim.retCorrLen > 0 && CFG.sim.speckleCorrLen > 0, ...
        'CFG.sim.*CorrLen мають бути > 0');
    tp_assert(CFG.sim.retMax >= CFG.sim.retMin, 'CFG.sim.retMax має бути >= CFG.sim.retMin');
end
end
