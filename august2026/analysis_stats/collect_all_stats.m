function T = collect_all_stats(CFG)
% COLLECT_ALL_STATS  Збирає ВСІ stats.*.txt з Fig1–Fig7 у єдину таблицю.
%   Результат кешується в all_stats.mat (CFG.outRoot) — повторний виклик
%   читає кеш, якщо CFG.forceReparse == false.
%
%   T = collect_all_stats(CFG)

cacheFile = fullfile(CFG.outRoot, 'all_stats.mat');

%% ─── Кеш ──────────────────────────────────────────────────────────────
if ~CFG.forceReparse && isfile(cacheFile)
    fprintf('Читаю кеш: %s\n', cacheFile);
    S = load(cacheFile, 'T');
    T = S.T;
    fprintf('  %d рядків з кешу\n', height(T));
    return;
end

%% ─── Сканувати stats.*.*.txt ──────────────────────────────────────────
% Шукаємо у FigN/ підтеках
allFiles = {};
for fi = 1:7
    figDir = fullfile(CFG.dataRoot, sprintf('Fig%d', fi));
    if ~isfolder(figDir), continue; end
    L = dir(fullfile(figDir, 'stats.*.txt'));
    for k = 1:numel(L)
        % Перевірити, що це stats.<type>.<algo>.txt (3 крапки в імені)
        dots = count(L(k).name, '.');
        if dots >= 3
            allFiles{end+1} = fullfile(L(k).folder, L(k).name); %#ok<AGROW>
        end
    end
end

fprintf('Знайдено %d файлів stats.*.txt\n', numel(allFiles));

%% ─── Парсинг ──────────────────────────────────────────────────────────
tables = {};
for i = 1:numel(allFiles)
    [~, fname] = fileparts(allFiles{i});
    fprintf('  [%2d/%d] %s ...', i, numel(allFiles), fname);
    try
        Ti = parse_stats_txt(allFiles{i});
        if ~isempty(Ti) && height(Ti) > 0
            tables{end+1} = Ti; %#ok<AGROW>
            fprintf(' %d рядків\n', height(Ti));
        else
            fprintf(' порожній\n');
        end
    catch ME
        fprintf(' ПОМИЛКА: %s\n', ME.message);
    end
end

%% ─── Злиття ──────────────────────────────────────────────────────────
if isempty(tables)
    T = table();
    fprintf(2, 'Жодного рядка не вдалось зібрати!\n');
    return;
end

T = vertcat(tables{:});
fprintf('Усього: %d рядків\n', height(T));

%% ─── Зберегти кеш ────────────────────────────────────────────────────
if ~exist(CFG.outRoot, 'dir'), mkdir(CFG.outRoot); end
save(cacheFile, 'T', '-v7.3');
fprintf('Кеш збережено: %s\n', cacheFile);

end
