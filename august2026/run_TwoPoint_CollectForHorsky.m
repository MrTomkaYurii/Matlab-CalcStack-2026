function run_TwoPoint_CollectForHorsky(cfgOverride)
% RUN_TWOPOINT_COLLECTFORHORSKY  Збирає розкидані result.mat (по зразках,
%   прикладах, фазових вибірках, кроках) в ОКРЕМИЙ .mat на КОЖЕН приклад і
%   алгоритм (приклади 1/2/3 НЕ зливаються в один файл) — лише дані
%   (модуль/аргумент f_ik), без картинок, окремо від CFG.paths.saveRoot,
%   для розшарювання (М. Горському).
%
%   Незалежний від основного розрахунку: НІЧОГО не рахує заново, лише
%   читає вже збережені result.mat (core/tp_collect_sample_for_horsky.m —
%   та сама функція, яку run_TwoPoint_Pipeline викликає автоматично одразу
%   як зразок дорахований). Можна запускати будь-коли, повторно, навіть
%   якщо частина зразків/прикладів ще не порахована — просто збере, що є.
%
%   CFG.horsky.algorithms — який(і) алгоритм(и) збирати: підмножина
%   {'orthogonal','generalized'} (див. config/cfg_TwoPoint.m). Корисно
%   звузити до одного, якщо інший ще рахується, а перший уже готовий і
%   не хочеться чекати.
%
%   Використання:
%       run_TwoPoint_CollectForHorsky            % бере config/cfg_TwoPoint
%       run_TwoPoint_CollectForHorsky(myCFG)      % власна структура CFG
%
%   Вихід (на кожен приклад ОКРЕМО): CFG.paths.horskyRoot\<Зразок>_<Приклад>_orthogonal.mat
%          (змінна: orthogonal) і ..._generalized.mat (змінна: generalized)
%       orthogonal.phase_0to<D>deg.<OX_step_D|OY_step_D>.<fXX>.mod/.arg
%       generalized.phase_0to<D>deg.step_<D>.<fXX>.mod/.arg
%   (докладніше — README.txt поряд з файлами)

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), fullfile(here,'core'));

if nargin >= 1 && isstruct(cfgOverride)
    CFG = cfgOverride;
else
    CFG = cfg_TwoPoint();
end

if ~exist(CFG.paths.horskyRoot,'dir'); mkdir(CFG.paths.horskyRoot); end

fprintf('=== Collect for Horsky ===\n');
for s = 1:numel(CFG.samples)
    sampleName = CFG.samples{s};
    [nFilesOrtho, nFilesGen] = tp_collect_sample_for_horsky(CFG, sampleName);
    if nFilesOrtho > 0
        fprintf('  [%s] %d *_orthogonal.mat (по прикладах)\n', sampleName, nFilesOrtho);
    end
    if nFilesGen > 0
        fprintf('  [%s] %d *_generalized.mat (по прикладах)\n', sampleName, nFilesGen);
    end
    if nFilesOrtho == 0 && nFilesGen == 0
        fprintf('  [%s] пропущено (ще нічого не пораховано)\n', sampleName);
    end
end

% README пишеться ПІСЛЯ збору (не до) — щоб розділ "поточний стан" нижче
% відображав те, що РЕАЛЬНО щойно записано в теку, а не порожню обіцянку.
writeReadme(CFG.paths.horskyRoot);

fprintf('=== done. %s ===\n', CFG.paths.horskyRoot);
end

% ------------------------------------------------------------------------
function writeReadme(root)
txt = sprintf([ ...
    'Структура даних (для мультифрактального аналізу)\n' ...
    '==================================================\n\n' ...
    'ЦЕ ОПИС ЗАГАЛЬНОЇ СХЕМИ (як влаштований формат файлів) — не гарантія,\n' ...
    'що ВСЕ нижче перелічене вже в теці. Що РЕАЛЬНО зараз є на диску — див.\n' ...
    '"Поточний стан" У КІНЦІ цього файлу (там же й дата генерації).\n\n' ...
    'ОКРЕМИЙ .mat-файл на КОЖЕН приклад і алгоритм (приклади 1/2/3 НЕ\n' ...
    'зливаються в один файл): <Зразок>_<Приклад>_orthogonal.mat і\n' ...
    '<Зразок>_<Приклад>_generalized.mat (напр. Мозг_1_orthogonal.mat,\n' ...
    'Мозг_1_generalized.mat, Мозг_2_orthogonal.mat, ..., Мозг_3_generalized.mat\n' ...
    '- до 6 файлів на зразок Мозг при 3 прикладах x 2 алгоритми, КОЛИ обидва\n' ...
    'алгоритми пораховані для всіх прикладів).\n' ...
    'Змінна всередині НАЗВАНА за алгоритмом (не узагальнене "DATA"):\n\n' ...
    '  У <Зразок>_<Приклад>_orthogonal.mat - змінна orthogonal:\n' ...
    '    orthogonal.phase_0to<D>deg.<OX_step_D|OY_step_D>.<fXX>.mod   - модуль,    NxN double\n' ...
    '    orthogonal.phase_0to<D>deg.<OX_step_D|OY_step_D>.<fXX>.arg   - аргумент (рад), NxN double\n\n' ...
    '  У <Зразок>_<Приклад>_generalized.mat - змінна generalized:\n' ...
    '    generalized.phase_0to<D>deg.step_<D>.<fXX>.mod\n' ...
    '    generalized.phase_0to<D>deg.step_<D>.<fXX>.arg\n\n' ...
    'phase_0to<D>deg - фазове вікно [0, U] у градусах (D = U у градусах):\n' ...
    '         phase_0to360deg (майже без фільтра) ... phase_0to45deg\n' ...
    '         (найвужче вікно). Полів 8, рівним кроком 45 град (= 0.25*pi):\n' ...
    '         360, 315, 270, 225, 180, 135, 90, 45. Опорна фаза =\n' ...
    '         arg(Ey)-arg(Ex) освітлення inRC (праве циркулярне) -\n' ...
    '         азимутально інваріантне.\n' ...
    'D   - крок (відстань між точками, у пікселях). Проєктний повний набір:\n' ...
    '      1, 2, 4, 8, 16, 32 — але в конкретному файлі можуть бути НЕ ВСІ\n' ...
    '      (лише ті, що вже пораховані на момент збору — див. "Поточний стан").\n' ...
    'fXX - елемент двоточкової матриці Мюллера, XX = 11..44 (16 елементів).\n' ...
    'OX/OY - напрям ортогонального сканування (окремо, без злиття).\n' ...
    'generalized (файл *_generalized.mat) - узагальнений алгоритм: повний\n' ...
    '  2D-скан з усередненням по першій точці (це і є "об''єднана" XY-карта).\n' ...
    '\n' ...
    'Файли переписуються щоразу, коли зразок дораховується (автоматично, з\n' ...
    'run_TwoPoint_Pipeline) або коли цей скрипт запускається вручну.\n' ...
    '\n']);

txt = [txt inventoryText(root)];
fid = fopen(fullfile(root,'README.txt'), 'w', 'n', 'UTF-8');
fwrite(fid, txt, 'char');
fclose(fid);
end

% ------------------------------------------------------------------------
function txt = inventoryText(root)
% Реальний перелік .mat-файлів, які ЗАРАЗ лежать у теці (не проєктна
% схема вище, а факт) — генерується щоразу заново при записі README, тож
% завжди відповідає останньому запуску збору.
d = dir(fullfile(root, '*.mat'));
names = sort({d.name});

lines = { ...
    'Поточний стан (на момент генерації цього README)', ...
    '=================================================='};
lines{end+1} = sprintf('Згенеровано: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
lines{end+1} = '';
if isempty(names)
    lines{end+1} = '(поки немає жодного зібраного файлу)';
else
    lines{end+1} = sprintf('%d файл(ів):', numel(names));
    for i = 1:numel(names)
        lines{end+1} = ['  ' names{i}]; %#ok<AGROW>
    end
end
txt = sprintf('%s\n', strjoin(lines, char(10)));
end
