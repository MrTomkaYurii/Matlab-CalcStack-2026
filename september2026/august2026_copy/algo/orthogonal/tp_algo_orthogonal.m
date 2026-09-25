function R = tp_algo_orthogonal(IMG, CFG, sampleName)
% TP_ALGO_ORTHOGONAL  Ортогонально-направлене двоточкове сканування, на кожне рознесення.
%   Реалізує "+Ортогонально-направленный алгоритм x_y":
%     * уздовж X друга точка стоїть у r2 = r1 + (d,0)
%     * уздовж Y друга точка стоїть у r2 = r1 + (0,d)
%   Для кожного рознесення d із CFG.ortho.steps (напр. 1,2,4,8,16 px) будується
%   ОКРЕМА карта (без усереднення між рознесеннями, без злиття X та Y).
%   Крайові пікселі без пари лишаються NaN (це живить контроль якості).
%
%   Вихідні напрями звуться  OX_d<d>  та  OY_d<d>, тож кожне рознесення й
%   напрям потрапляють у власну теку результатів і заголовок фігури.
%
%   R : канонічна структура результату, яку споживає tp_visualize.

N     = CFG.crop.size;
els   = CFG.elements;
steps = CFG.ortho.steps;
ax    = 1:N;
% ПРОРІДЖЕННЯ перших точок (крок першої точки): 1 => усі пікселі (без прорідження)
posStep = 1;
if isfield(CFG.ortho,'posStep'), posStep = CFG.ortho.posStep; end
% Які напрями рахувати: за замовчуванням обидва; можна звузити до одного
% (напр. CFG.ortho.directions = {'OY'}), щоб не перераховувати інший.
directions = {'OX','OY'};
if isfield(CFG.ortho,'directions') && ~isempty(CFG.ortho.directions)
    directions = CFG.ortho.directions;
end
doOX = any(strcmpi(directions,'OX'));
doOY = any(strcmpi(directions,'OY'));

R = tp_base_result('orthogonal', sampleName, CFG);
R.dirs = {};

% ---- на кожне рознесення d: спершу OX, потім OY (якщо увімкнені) ----
for s = 1:numel(steps)
    d = steps(s);
    if d >= N, continue; end

    if doOX
        % OX: r2 = r1 + (d,0); перші точки проріджені на posStep по обох осях
        dir = sprintf('OX_step_%d', d);
        rr = 1:posStep:N;
        c1 = 1:posStep:(N-d);  c2 = c1 + d;
        F  = tp_fik_pair(tp_slice(IMG,rr,c1), tp_slice(IMG,rr,c2));
        for e = 1:numel(els)
            M = complex(nan(N));  M(rr,c1) = F.(els{e});
            R.data.(dir).(els{e}) = pack(M);
        end
        R = add_dir(R, dir, ax, d, 'OX');
    end

    if doOY
        % OY: r2 = r1 + (0,d)
        dir = sprintf('OY_step_%d', d);
        r1 = 1:posStep:(N-d);  r2 = r1 + d;
        cc = 1:posStep:N;
        F  = tp_fik_pair(tp_slice(IMG,r1,cc), tp_slice(IMG,r2,cc));
        for e = 1:numel(els)
            M = complex(nan(N));  M(r1,cc) = F.(els{e});
            R.data.(dir).(els{e}) = pack(M);
        end
        R = add_dir(R, dir, ax, d, 'OY');
    end
end

R.params = struct('steps', steps, 'posStep', posStep);
end

% ------------------------------------------------------------------------
function R = add_dir(R, dir, ax, d, base)
R.axes.(dir)  = struct('x',ax,'y',ax);
R.label.(dir) = struct('x','x (px)','y','y (px)');
R.sep.(dir)   = struct('direction',base,'delta',d);   % метадані рознесення
R.dirs{end+1} = dir;
end

function s = pack(z)
s = struct('cplx', z, 'mod', abs(z), 'arg', atan2(imag(z), real(z)));
end
