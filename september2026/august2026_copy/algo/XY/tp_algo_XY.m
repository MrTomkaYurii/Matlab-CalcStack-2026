function R = tp_algo_XY(IMG, CFG, sampleOut, step, RorthoCache)
% TP_ALGO_XY  ЗВЕДЕНА карта хреста x/y — сума OX + OY БЕЗ усереднення.
%
%   За документом «Ортогонально-направленный алгоритм..._x_y_с_единой_картой»,
%   розд. 7: «после раздельного накопления горизонтальных и вертикальных
%   результатов выполняется операция их объединения». Тут об'єднання —
%   КОМПЛЕКСНА СУМА  OX + OY  (БЕЗ ділення), до модуля/аргумента.
%
%   Джерело OX/OY (окремі карти НЕ зберігаються — тільки зведена XY),
%   за пріоритетом:
%     1) RorthoCache (немаскований orthogonal-результат У ПАМ'ЯТІ, переданий
%        викликом) — так робить run_TwoPoint_Pipeline.m/run_TwoPoint_
%        FillMissing.m (Етап 1 ТЗ, фазові вікна per-element): XY має бути
%        просумований з ПОВНОГО OX/OY, а потім вікно накладається на СУМУ
%        по ЇЇ ВЛАСНОМУ arg (tp_phase_window_element) — якби замість цього
%        читали вже провіконений диск, сума на пікселях де рукав OX (чи OY)
%        випав з ЧУЖОГО вікна вийшла б частковою (лише один рукав), а не
%        істинним OX+OY.
%     2) на диску Є orthogonal/OX/step_<d>/result.mat + .../OY/... — ЧИТАЄ
%        їх, нічого не перераховує (сумісність зі старими прогонами/
%        ручними викликами поза пайплайном).
%     3) НЕМА жодного — рахує OX_d = f_ik(r1, r1+(d,0)), OY_d = f_ik(r1,
%        r1+(0,d)) у ПАМ'ЯТІ з IMG (2 виклики tp_fik_pair, як
%        tp_algo_orthogonal на один крок) і НЕ зберігає їх окремо.
%
%   CFG.XY.normalize (типово true) — поділити ВСІ елементи на медіану |XY_11|
%   (m_ik = f_ik / f_11, скалярно): прибирає довільний масштаб ~1e-6, робить
%   |f_ik| ~ O(1). Це поділ на ОДНЕ число: просторова структура й arg НЕ
%   змінюються. Множник -> R.params.normScale.
%
%   IMG         : поля (для розрахунку OX/OY, коли RorthoCache/orthogonal-
%                 результату нема). Може бути [] — тоді кидається помилка.
%   sampleOut   : тека зразка, як усюди в пайплайні.
%   step        : крок d (px). Окрема XY-карта на кожен d із CFG.ortho.steps
%                 (тека XY/step_<d>/), як у generalized.
%   RorthoCache : (опційно) канонічний R з tp_algo_orthogonal, УЖЕ порахований
%                 у пам'яті на ПОВНОМУ кадрі (без фазової маски) — якщо
%                 переданий і містить OX_step_<d>/OY_step_<d>, використовується
%                 напряму, диск і IMG ігноруються.
%
%   R : канонічна структура результату (один напрям 'step_<d>') для tp_visualize.

N   = CFG.crop.size;
dir = sprintf('step_%d', step);

oxFile = fullfile(CFG.paths.saveRoot, sampleOut, 'orthogonal', 'OX', dir, 'result.mat');
oyFile = fullfile(CFG.paths.saveRoot, sampleOut, 'orthogonal', 'OY', dir, 'result.mat');

if nargin >= 5 && ~isempty(RorthoCache)
    oxDir = sprintf('OX_step_%d', step);  oyDir = sprintf('OY_step_%d', step);
    tp_assert(isfield(RorthoCache.data, oxDir) && isfield(RorthoCache.data, oyDir), ...
        'tp_algo_XY: RorthoCache бракує %s/%s (крок %d не в CFG.ortho.steps під час розрахунку orthogonal?)', ...
        oxDir, oyDir, step);
    els  = fieldnames(RorthoCache.data.(oxDir));
    OXd  = @(el) RorthoCache.data.(oxDir).(el).cplx;
    OYd  = @(el) RorthoCache.data.(oyDir).(el).cplx;
    srcTxt = 'кешований orthogonal (у пам''яті, немаскований)';
elseif isfile(oxFile) && isfile(oyFile)
    Sx = load(oxFile, 'Rd');  Sy = load(oyFile, 'Rd');
    oxDir = Sx.Rd.dirs{1};  oyDir = Sy.Rd.dirs{1};
    els  = intersect(fieldnames(Sx.Rd.data.(oxDir)), fieldnames(Sy.Rd.data.(oyDir)), 'stable');
    OXd  = @(el) Sx.Rd.data.(oxDir).(el).cplx;
    OYd  = @(el) Sy.Rd.data.(oyDir).(el).cplx;
    srcTxt = 'orthogonal-результат (з диску)';
else
    tp_assert(~isempty(IMG) && isstruct(IMG), ...
        ['tp_algo_XY: немає orthogonal OX/OY для кроку %d, і поля IMG не передані.\n' ...
         '  Запусти через run_TwoPoint_Pipeline (він передає IMG) або спершу порахуй ''orthogonal''.'], step);
    [OXm, OYm, els] = local_axes(IMG, CFG, N, step);
    OXd = @(el) OXm.(el);
    OYd = @(el) OYm.(el);
    srcTxt = 'обчислено в пам''яті (OX+OY)';
end

R = tp_base_result('XY', sampleOut, CFG);
R.elements    = els;
R.dirs        = {dir};
R.axes.(dir)  = struct('x', 1:N, 'y', 1:N);
R.label.(dir) = struct('x', 'x (px)', 'y', 'y (px)');

fprintf('  [XY] %s: OX + OY (крок %d, без усереднення) — %s\n', sampleOut, step, srcTxt);

vc = zeros(N);
for e = 1:numel(els)
    mx = OXd(els{e});  my = OYd(els{e});
    okx = isfinite(mx);  oky = isfinite(my);

    S = complex(zeros(N));
    S(okx) = S(okx) + mx(okx);
    S(oky) = S(oky) + my(oky);            % КОМПЛЕКСНА сума OX + OY, без ділення
    S(~(okx | oky)) = complex(NaN);       % жоден промінь -> сума не визначена

    R.data.(dir).(els{e}) = struct('cplx', S, 'mod', abs(S), 'arg', atan2(imag(S), real(S)));
    if e == 1, vc = double(okx) + double(oky); end   % 0..2 променів на піксель
end

% --- нормування: m_ik = f_ik / медіану|XY_11| (скаляр) ------------------
% Прибирає довільний масштаб реконструкції (~1e-6). ЛИШЕ поділ на одне
% число: карти й arg не змінюються. Вимкнути: CFG.XY.normalize = false.
doNorm = ~isfield(CFG,'XY') || ~isfield(CFG.XY,'normalize') || CFG.XY.normalize;
normScale = 1;
if doNorm
    if any(strcmp(els, 'f11'))
        v = R.data.(dir).f11.mod;
        v = v(isfinite(v) & v > 0);
        if ~isempty(v), normScale = median(v); end
    else
        fprintf(2, '   [XY] CFG.XY.normalize=true, але ''f11'' немає в CFG.elements — нормування пропущено\n');
    end
    if isfinite(normScale) && normScale > 0 && normScale ~= 1
        for e = 1:numel(els)
            z = R.data.(dir).(els{e}).cplx / normScale;
            R.data.(dir).(els{e}) = struct('cplx', z, 'mod', abs(z), 'arg', atan2(imag(z), real(z)));
        end
        fprintf('  [XY] нормовано: m_ik = f_ik / %.3g (медіана |XY_11|)\n', normScale);
    end
end

R.params = struct('step', step, 'combine', 'complex-sum', 'source', srcTxt, ...
                  'normalize', doNorm, 'normScale', normScale);
R.params.validCount.(dir) = vc;
end

% ======================================================================
function [OXm, OYm, els] = local_axes(IMG, CFG, N, d)
% OX_d = f_ik(r1, r1+(d,0)),  OY_d = f_ik(r1, r1+(0,d)) — у пам'яті, як
% tp_algo_orthogonal на один крок (без збереження окремих карт).
els = CFG.elements;
posStep = 1;
if isfield(CFG,'ortho') && isfield(CFG.ortho,'posStep'), posStep = CFG.ortho.posStep; end

rr = 1:posStep:N;        cc = 1:posStep:N;
cX = 1:posStep:(N-d);    rY = 1:posStep:(N-d);

Fx = tp_fik_pair(tp_slice(IMG, rr, cX), tp_slice(IMG, rr, cX + d));
Fy = tp_fik_pair(tp_slice(IMG, rY, cc), tp_slice(IMG, rY + d, cc));

OXm = struct();  OYm = struct();
for e = 1:numel(els)
    MX = complex(nan(N));  MX(rr, cX) = Fx.(els{e});
    MY = complex(nan(N));  MY(rY, cc) = Fy.(els{e});
    OXm.(els{e}) = MX;
    OYm.(els{e}) = MY;
end
end
