function D = tz_read(FIG, sample, example, algo, win)
% TZ_READ  Карти f11..f44 одного зразка / прикладу / алгоритму / фазового вікна
%   (tp_paper_read — читає готовий result.mat, нічого не рахує) з кешем.
%
%   algo : 'XY' | 'OY' | 'OX' | 'generalized'
%   win  : верхня межа вікна в частках π: 2, 1.75, 1.5, ..., 0.25
%
%   Нормування масштабу (tp_paper_normalize) кешується за першим прочитаним вікном,
%   тому спершу ЗАВЖДИ читається 0–2π цього зразка/прикладу/алгоритму — як у
%   рисунках статті (там вікна йдуть від 0–2π), і числа |f| збігаються з ними.
%
%   tz_read('reset') — очистити кеш (і кеш нормування).

persistent C
if nargin == 1 && ischar(FIG) && strcmpi(FIG, 'reset')
    C = containers.Map();  tp_paper_normalize('reset');  D = [];  return;
end
if isempty(C); C = containers.Map(); end

k = round((2 - win) / 0.25) + 1;
assert(k >= 1 && k <= 8 && abs(2 - 0.25*(k-1) - win) < 1e-9, 'tz_read: немає вікна 0–%gπ', win);
key = sprintf('%s|%s|%s|%d', sample, example, algo, k);
if isKey(C, key); D = C(key); return; end

if k ~= 1 && ~isKey(C, sprintf('%s|%s|%s|%d', sample, example, algo, 1))
    tz_read(FIG, sample, example, algo, 2);                 % засіяти нормування з 0–2π
end
switch upper(algo)
    case 'XY',  v = struct('tag','XY', 'algo','XY', 'dir','');
    case {'OX','OY'}, v = struct('tag',upper(algo), 'algo','orthogonal', 'dir',upper(algo));
    case 'GENERALIZED', v = struct('tag','generalized', 'algo','generalized', 'dir','');
    otherwise, error('tz_read: невідомий алгоритм %s', algo);
end
D = tp_paper_read(FIG, sample, example, v, sprintf('phase_%02d_*', k));
D.meta = struct('sample',sample, 'example',example, 'algo',upper(algo), 'win',win);
C(key) = D;
end
