function R = tp_algo_XY(CFG, sampleOut, step)
% TP_ALGO_XY  ЗВЕДЕНА карта хреста x/y — сума OX + OY БЕЗ усереднення.
%
%   За документом «Ортогонально-направленный алгоритм..._x_y_с_единой_картой»,
%   розд. 7: «после раздельного накопления горизонтальных и вертикальных
%   результатов выполняется операция их объединения». Тут об'єднання —
%   КОМПЛЕКСНА СУМА  OX + OY  (БЕЗ ділення), до модуля/аргумента.
%
%   НЕ рахує f_ik заново і НЕ пересейвлює OX/OY. Читає вже збережені
%       orthogonal/OX/step_<d>/result.mat
%       orthogonal/OY/step_<d>/result.mat
%   (їх пише tp_algo_orthogonal) і складає покомплексно. Отже 'orthogonal'
%   має бути порахований ДО 'XY' для тих самих зразка / фазового вікна /
%   кроку: постав обидва в CFG.algorithms (пайплайн обробляє 'XY' після
%   'orthogonal'), або 'orthogonal' лишився з попереднього прогону.
%
%   sampleOut : тека зразка (може містити фазову підтеку), як усюди в пайплайні.
%   step      : крок d (px). Окрема XY-карта на кожен d із CFG.ortho.steps
%               (тека XY/step_<d>/), як у generalized.
%
%   R : канонічна структура результату (один напрям 'step_<d>') для tp_visualize.

N = CFG.crop.size;

oxFile = fullfile(CFG.paths.saveRoot, sampleOut, 'orthogonal', 'OX', sprintf('step_%d', step), 'result.mat');
oyFile = fullfile(CFG.paths.saveRoot, sampleOut, 'orthogonal', 'OY', sprintf('step_%d', step), 'result.mat');
tp_assert(isfile(oxFile) && isfile(oyFile), ...
    ['tp_algo_XY: немає orthogonal OX/OY для кроку %d.\n' ...
     '  Спочатку порахуй ''orthogonal'' (додай його в CFG.algorithms — ''XY'' іде після нього),\n' ...
     '  і в CFG.ortho.directions мають бути ОБИДВА напрями {''OX'',''OY''}.\n' ...
     '  Очікувані файли:\n    %s\n    %s'], step, oxFile, oyFile);

Sx = load(oxFile, 'Rd');  OX = Sx.Rd;
Sy = load(oyFile, 'Rd');  OY = Sy.Rd;
oxDir = OX.dirs{1};                       % 'OX_step_<d>'
oyDir = OY.dirs{1};                       % 'OY_step_<d>'

% елементи беремо ті, що РЕАЛЬНО є в orthogonal-результаті (а не CFG.elements —
% раптом конфіг звужували між прогонами)
els = intersect(fieldnames(OX.data.(oxDir)), fieldnames(OY.data.(oyDir)), 'stable');

dir = sprintf('step_%d', step);
R = tp_base_result('XY', sampleOut, CFG);
R.elements     = els;
R.dirs         = {dir};
R.axes.(dir)   = struct('x', 1:N, 'y', 1:N);
R.label.(dir)  = struct('x', 'x (px)', 'y', 'y (px)');

fprintf('  [XY] %s: OX + OY (крок %d, без усереднення) з orthogonal-результату\n', sampleOut, step);

vc = zeros(N);
for e = 1:numel(els)
    mx = OX.data.(oxDir).(els{e}).cplx;
    my = OY.data.(oyDir).(els{e}).cplx;
    okx = isfinite(mx);  oky = isfinite(my);

    S = complex(zeros(N));
    S(okx) = S(okx) + mx(okx);
    S(oky) = S(oky) + my(oky);            % КОМПЛЕКСНА сума OX + OY, без ділення
    S(~(okx | oky)) = complex(NaN);       % жоден промінь -> сума не визначена

    R.data.(dir).(els{e}) = struct('cplx', S, 'mod', abs(S), 'arg', angle(S));
    if e == 1, vc = double(okx) + double(oky); end   % 0..2 променів на піксель
end

R.params = struct('step', step, 'combine', 'complex-sum', 'source', 'orthogonal OX+OY');
R.params.validCount.(dir) = vc;
end
