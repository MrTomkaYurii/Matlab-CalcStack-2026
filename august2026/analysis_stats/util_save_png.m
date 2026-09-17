function util_save_png(fig, folder, filename, dpi)
% UTIL_SAVE_PNG  Зберігає фігуру як PNG і закриває її.
%   util_save_png(fig, folder, filename)
%   util_save_png(fig, folder, filename, dpi)

if nargin < 4, dpi = 200; end
if ~exist(folder, 'dir'), mkdir(folder); end

% Примусово накладаємо чисту білу тему на фігуру та осі
apply_light_theme(fig);

fpath = fullfile(folder, [filename '.png']);
exportgraphics(fig, fpath, 'Resolution', dpi, 'BackgroundColor', 'white');
fprintf('  -> %s\n', fpath);
close(fig);
end
