function R = tp_algo_xysum(IMG, CFG, sampleName)
% TP_ALGO_XYSUM  Хрестоподібне (ТІЛЬКИ x і y) двоточкове сканування, зведене
%   в ОДНУ карту КОМПЛЕКСНОЮ СУМОЮ — БЕЗ ділення на кількість.
%
%   За документом «Ортогонально-направленный алгоритм..._x_y_с_единой_картой»
%   (розд. 2, 7-8), але свідомо БЕЗ усереднення розд. 6-7: об'єднання
%   горизонтального й вертикального напрямів виконується сумою, не середнім
%   (пор. polar: та сама сира сума, але по КОЛУ кутів).
%
%   Для кожного кроку d із CFG.xysum.steps (px):
%       OX_d(r1) = f_ik( r1, r1 + (d,0) )        зсув другої точки по +x
%       OY_d(r1) = f_ik( r1, r1 + (0,d) )        зсув другої точки по +y
%       XY_d(r1) = OX_d(r1) + OY_d(r1)           КОМПЛЕКСНА сума (БЕЗ /2)
%   Друга точка поза кадром / у NaN фазового вікна -> цей промінь НЕ входить
%   у суму для того пікселя (R.params.validCount фіксує, 0..2).
%
%   Комплексне складання — ДО модуля/аргумента (розд. 7 документа): так
%   циклічні фази не усереднюються арифметично.
%
%   Осьові карти OX / OY зберігаються окремо (розд. 8: оцінка орієнтаційної
%   анізотропії) — так само, як PERP/OX/OY у polar.
%
%   Відмінності:
%     - orthogonal : той самий хрест x/y, але OX/OY лишаються РОЗДІЛЬНІ (без XY);
%     - polar      : та сама сира комплексна сума, але по колу кутів, не по осях;
%     - generalized: повний 2D-скан (Δx,Δy) з усередненням по перших точках.
%
%   R : канонічна структура результату (tp_base_result) для tp_visualize.

N     = CFG.crop.size;
els   = CFG.elements;  nE = numel(els);
X     = CFG.xysum;
steps = X.steps;
ax    = 1:N;

posStep = 1;
if isfield(X,'posStep'), posStep = X.posStep; end

R = tp_base_result('xysum', sampleName, CFG);
R.dirs = {};

fprintf('  [xysum] %s: кроки d = %s, posStep=%d (XY = OX+OY, без ділення)\n', ...
        sampleName, mat2str(steps), posStep);

for s = 1:numel(steps)
    d = steps(s);
    if d >= N, continue; end

    rr = 1:posStep:N;                 % рядки для OX (кожен рядок має правого сусіда)
    cc = 1:posStep:N;                 % стовпці для OY
    cX = 1:posStep:(N-d);             % перші точки OX: правий сусід на +d у межах кадру
    rY = 1:posStep:(N-d);             % перші точки OY: нижній сусід на +d у межах кадру

    Fx = tp_fik_pair(tp_slice(IMG, rr, cX), tp_slice(IMG, rr, cX + d));
    Fy = tp_fik_pair(tp_slice(IMG, rY, cc), tp_slice(IMG, rY + d, cc));

    dXY = sprintf('XY_step_%d', d);
    dOX = sprintf('OX_step_%d', d);
    dOY = sprintf('OY_step_%d', d);

    for e = 1:nE
        MX = complex(nan(N));  MX(rr, cX) = Fx.(els{e});
        MY = complex(nan(N));  MY(rY, cc) = Fy.(els{e});

        okX = isfinite(MX);  okY = isfinite(MY);
        S = complex(zeros(N));
        S(okX) = S(okX) + MX(okX);
        S(okY) = S(okY) + MY(okY);            % КОМПЛЕКСНА сума OX+OY, без /2
        S(~(okX | okY)) = complex(NaN);       % жоден промінь -> сума не визначена

        R.data.(dXY).(els{e}) = pack(S);
        R.data.(dOX).(els{e}) = pack(MX);
        R.data.(dOY).(els{e}) = pack(MY);
    end

    % скільки променів (0..2) реально ввійшло в суму на піксель — за першим
    % елементом (маска валідності спільна для всіх f_ik: одна точка 2, одне
    % фазове вікно)
    MX1 = complex(nan(N));  MX1(rr, cX) = Fx.(els{1});
    MY1 = complex(nan(N));  MY1(rY, cc) = Fy.(els{1});
    R.params.validCount.(dXY) = double(isfinite(MX1)) + double(isfinite(MY1));

    R = add_dir(R, dXY, ax, d, 'XY');
    R = add_dir(R, dOX, ax, d, 'OX');
    R = add_dir(R, dOY, ax, d, 'OY');
end

R.params.steps   = steps;
R.params.posStep = posStep;
R.params.combine = 'complex-sum';            % XY = OX + OY, без ділення
end

% ------------------------------------------------------------------------
function R = add_dir(R, dir, ax, d, base)
R.axes.(dir)  = struct('x',ax,'y',ax);
R.label.(dir) = struct('x','x (px)','y','y (px)');
R.sep.(dir)   = struct('direction',base,'delta',d);   % -> теки <base>\step_<d>
R.dirs{end+1} = dir;
end

function s = pack(z)
s = struct('cplx', z, 'mod', abs(z), 'arg', angle(z));
end
