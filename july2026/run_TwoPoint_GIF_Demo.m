function run_TwoPoint_GIF_Demo()
% RUN_TWOPOINT_GIF_DEMO  Будує демонстраційні GIF-анімації механіки двох
%   алгоритмів (ортогонального та узагальненого) на малому синтетичному
%   зразку. Кожен кадр має пряме пояснення на картинці: формулу та живий
%   числовий приклад поточного кроку — щоб було видно не лише картинку,
%   а й ЯК саме воно накладається та рахується.
%
%   Використовує ті самі функції (tp_fik_pair, tp_sim_speckle_BT), що й
%   бойовий розрахунок, лише на зменшеному зображенні — заради швидкості
%   й розміру gif.
%
%   Результати: july2026/gif/orthogonal_algorithm.gif
%               july2026/gif/generalized_algorithm.gif

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), fullfile(here,'core'), fullfile(here,'simulation'), ...
        fullfile(here,'viz'),    fullfile(here,'gif'));

outDir = fullfile(here,'gif');
if ~exist(outDir,'dir'), mkdir(outDir); end

fprintf('=== Building demo GIFs ===\n');
fprintf('-- orthogonal algorithm --\n');
tp_gif_orthogonal(outDir);
fprintf('-- generalized algorithm --\n');
tp_gif_generalized(outDir);
fprintf('=== done: %s ===\n', outDir);
end
