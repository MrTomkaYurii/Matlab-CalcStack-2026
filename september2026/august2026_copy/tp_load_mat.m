function [IMG, warnings] = tp_load_mat(CFG, sampleName, exampleName)
% TP_LOAD_MAT  Завантажує вже РЕКОНСТРУЙОВАНІ КОМПЛЕКСНІ Ex,Ey з .mat файлів
%   (новий формат, серпень 2026): ex_<стан>.mat / ey_<стан>.mat, де
%   стан = освітлення ∈ {0,45,90,135,liv,prav}. Кожен .mat містить РІВНО
%   ОДНУ комплексну NxN матрицю (перевірено скриптом explore_mat_data.m).
%
%   На відміну від старого BMP-формату, тут НЕ потрібно рахувати √I чи
%   Стокс-параметри — амплітуда й фаза вже прямо в комплексному числі:
%     |Ex| = |ex|,  |Ey| = |ey|,  δ = angle(ey) − angle(ex)
%   (саме це й робить tp_fik_pair.m у цій копії проєкту).
%
%   IMG.(inPol).Ex, IMG.(inPol).Ey : NxN complex double
%   inPol ∈ {in0,in45,in90,in135,inliv,inprav,inRC}
%   inRC — псевдонім на CFG.mat.rcSource ('liv' або 'prav'): старим формулам
%   (розділ 4) потрібне рівно ОДНЕ освітлення "RC", а нових станів два.
%
%   Деякі вихідні .mat-файли виявились ДІЙСНИМИ (суцільні нулі) замість
%   комплексних — сира голограма для цих кадрів не мала інтерференційних
%   смуг (перевірено візуально: немає носійної частоти, на відміну від
%   робочих кадрів). За рішенням користувача (переголовити ці зразки
%   неможливо) — НЕ відкидаємо приклад цілком, а вантажимо канал як
%   0+0i і повертаємо явний список попереджень `warnings` (cellstr),
%   щоб ця прогалина була видно в результатах, а не мовчки загубилась.

if nargin < 3, exampleName = ''; end
warnings = {};

states  = {'0','45','90','135','liv','prav'};
inNames = {'in0','in45','in90','in135','inliv','inprav'};

% Де шукати файли: пробуємо кілька можливих вкладеностей, від найбільш
% конкретної до найбільш плоскої (структура реальних даних мінялась
% кілька разів, тож tp_load_mat лишається толерантним до всіх варіантів):
%   1) matRoot\<sample>\<example>\mat\ex_0.mat   (поточна: «Зразки - нові (серпень 2026) mat», кол. rez_cs)
%   2) matRoot\<sample>\mat\ex_0.mat             (зразок без підтек-прикладів)
%   3) matRoot\<sample>\ex_0.mat                 (стара плоска-на-зразок)
%   4) matRoot\ex_0.mat                          (повністю плоский, без зразків)
matRoot = CFG.paths.matRoot;
candidates = {};
if ~isempty(exampleName)
    candidates{end+1} = fullfile(matRoot, sampleName, exampleName, 'mat');
end
candidates{end+1} = fullfile(matRoot, sampleName, 'mat');
candidates{end+1} = fullfile(matRoot, sampleName);
candidates{end+1} = matRoot;

sampleDir = candidates{end};   % запасний варіант, якщо жоден не підійде
for c = 1:numel(candidates)
    if isfile(fullfile(candidates{c}, 'ex_0.mat'))
        sampleDir = candidates{c};
        break;
    end
end

N  = CFG.crop.size;  x0 = CFG.crop.x0;  y0 = CFG.crop.y0;

IMG = struct();
for s = 1:numel(states)
    exFile = fullfile(sampleDir, sprintf('ex_%s.mat', states{s}));
    eyFile = fullfile(sampleDir, sprintf('ey_%s.mat', states{s}));
    tp_assert(isfile(exFile), 'tp_load_mat: не знайдено %s', exFile);
    tp_assert(isfile(eyFile), 'tp_load_mat: не знайдено %s', eyFile);

    [Ex, badEx] = loadComplexVar(exFile);
    [Ey, badEy] = loadComplexVar(eyFile);
    if badEx, warnings{end+1} = sprintf('ex_%s.mat: дійсний/нульовий канал (не комплексний) -> завантажено як 0+0i', states{s}); end %#ok<AGROW>
    if badEy, warnings{end+1} = sprintf('ey_%s.mat: дійсний/нульовий канал (не комплексний) -> завантажено як 0+0i', states{s}); end %#ok<AGROW>
    tp_assert(isequal(size(Ex), size(Ey)), ...
        'tp_load_mat: ex_%s.mat і ey_%s.mat мають різний розмір', states{s}, states{s});
    tp_assert(size(Ex,1) >= y0+N-1 && size(Ex,2) >= x0+N-1, ...
        'tp_load_mat: %s (%dx%d) замалий для crop %d від (%d,%d)', ...
        exFile, size(Ex,1), size(Ex,2), N, x0, y0);

    IMG.(inNames{s}) = struct( ...
        'Ex', Ex(y0:y0+N-1, x0:x0+N-1), ...
        'Ey', Ey(y0:y0+N-1, x0:x0+N-1));
end

% псевдонім inRC -> CFG.mat.rcSource ('liv' чи 'prav', за замовчуванням 'prav')
rcSrc = 'prav';
if isfield(CFG,'mat') && isfield(CFG.mat,'rcSource'), rcSrc = CFG.mat.rcSource; end
IMG.inRC = IMG.(['in' rcSrc]);
end

% ------------------------------------------------------------------------
function [X, isBad] = loadComplexVar(fname)
S = load(fname);
vn = fieldnames(S);
tp_assert(numel(vn) == 1, ...
    'tp_load_mat: очікувалась 1 змінна у %s, знайдено %d', fname, numel(vn));
X = S.(vn{1});
tp_assert(isnumeric(X), 'tp_load_mat: %s не є числовим масивом', fname);
isBad = isreal(X);         % битий кадр = дійсний (мав бути комплексний)
if isBad
    X = complex(X);        % 0+0i (чи інше дійсне значення) — не відкидаємо, лише позначаємо
end
end
