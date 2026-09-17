function T = parse_stats_txt(filepath)
% PARSE_STATS_TXT  Парсить stats.<type>.<algo>.txt → MATLAB table (wide format).
%
%   T = parse_stats_txt('path/to/stats.moments.XY.txt')
%
%   Кожен рядок таблиці = один числовий рядок txt-файлу (один розподіл).
%   Колонки:
%     fig, statsType, pair, algo, sample, example   (ідентифікатори)
%     phase, phaseWidth                              (фазове вікно)
%     element, component                             (елемент f_ik, |f|/arg)
%     Z1..Z4, Lcorr, dH..D2                         (метрики, NaN якщо нерелевантні)
%     N                                              (кількість пікселів)
%
%   Формат txt створений paper_figures/make_stats_table.m:
%     - блок-заголовок: FigN.pair.algo.sample.example  (без пробілів)
%     - рядок даних:    0 - Xπ  fNN  |f|/arg  v1 v2 ... N
%     Для wavelet_cuts елемент може бути "f33 (a=4.9)" — два токени.

%% ─── 1. Ім'я файлу → statsType, algo; тека → fig ──────────────────────
[parentDir, fname] = fileparts(filepath);
[~, figDir] = fileparts(parentDir);

nameParts = strsplit(fname, '.');
if numel(nameParts) < 3
    warning('parse_stats_txt:name', 'Не вдалось розібрати ім''я: %s', fname);
    T = table(); return;
end
statsType = nameParts{2};        % moments | acf | psd | skeleton | wavelet | wavelet_cuts | multifractal | mueller
algo      = nameParts{3};        % XY | generalized | OX | OY
fig       = figDir;              % Fig1 .. Fig7

%% ─── 2. Список метрик за типом (йдуть ДО стовпця N) ───────────────────
switch statsType
    case {'moments','psd','skeleton','wavelet','wavelet_cuts','mueller'}
        mNames = {'Z1','Z2','Z3','Z4'};
    case 'acf'
        mNames = {'Z2','Z4','Lcorr'};
    case 'multifractal'
        mNames = {'dH','dH_L','dH_R','asym','D0','D1','D2'};
    otherwise
        mNames = {'Z1','Z2','Z3','Z4'};
end
nExpected = numel(mNames);

allMetrics = {'Z1','Z2','Z3','Z4','Lcorr','dH','dH_L','dH_R','asym','D0','D1','D2'};

%% ─── 3. Читаємо файл ──────────────────────────────────────────────────
fid = fopen(filepath, 'r', 'n', 'UTF-8');
raw = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
lines = raw{1};

%% ─── 4. Парсинг рядків ────────────────────────────────────────────────
curPair = ''; curSample = ''; curExample = '';
C = {};   % cell of structs, буде [C{:}] → struct array → table

for i = 1:numel(lines)
    line = lines{i};
    trimmed = strtrim(line);
    if isempty(trimmed), continue; end

    % ── Блок-заголовок: FigN.pair.algo.sample.example (без пробілів) ────
    if trimmed(1) == 'F' && contains(trimmed, '.') && ~contains(trimmed, ' ')
        parts = strsplit(trimmed, '.');
        if numel(parts) >= 5
            curPair    = parts{2};
            curSample  = parts{end-1};
            curExample = parts{end};
        end
        continue;
    end

    % ── Рядок даних: починається з "0 -" ────────────────────────────────
    if trimmed(1) ~= '0', continue; end
    tokens = strsplit(trimmed);
    if numel(tokens) < 6 || ~strcmp(tokens{2}, '-'), continue; end

    % Фазове вікно: "0 - 2π" або "0 - 0.75π"
    phase = [tokens{1} ' ' tokens{2} ' ' tokens{3}];

    % Ширина вікна (число перед π): "2π" → 2, "0.75π" → 0.75
    pw = regexp(tokens{3}, '([\d.]+)', 'tokens', 'once');
    phaseWidth = NaN;
    if ~isempty(pw), phaseWidth = str2double(pw{1}); end

    % ── Елемент і компонента ────────────────────────────────────────────
    % Звичайний формат: tokens{4}=f33, tokens{5}=|f|
    % wavelet_cuts:     tokens{4}=f33, tokens{5}=(a=4.9), tokens{6}=|f|
    % Визначаємо за тим, чи tokens{5} = '|f|' або 'arg'
    if any(strcmp(tokens{5}, {'|f|','arg'}))
        element = tokens{4};
        comp    = tokens{5};
        valStart = 6;
    elseif numel(tokens) >= 7 && any(strcmp(tokens{6}, {'|f|','arg'}))
        % wavelet_cuts: елемент = "f33 (a=4.9)"
        element = [tokens{4} ' ' tokens{5}];
        comp    = tokens{6};
        valStart = 7;
    else
        continue;   % невідомий формат рядка
    end

    % ── Числові значення ────────────────────────────────────────────────
    % str2double: '—' / нечислове → NaN автоматично
    vals = cellfun(@str2double, tokens(valStart:end));

    if numel(vals) > nExpected
        metricVals = vals(1:nExpected);
        N = vals(nExpected + 1);
    elseif numel(vals) == nExpected
        metricVals = vals;
        N = NaN;
    else
        metricVals = nan(1, nExpected);
        metricVals(1:numel(vals)) = vals;
        N = NaN;
    end

    % ── Збираємо рядок ──────────────────────────────────────────────────
    r.fig        = fig;
    r.statsType  = statsType;
    r.pair       = curPair;
    r.algo       = algo;
    r.sample     = curSample;
    r.example    = curExample;
    r.phase      = phase;
    r.phaseWidth = phaseWidth;
    r.element    = element;
    r.component  = comp;

    for m = 1:numel(allMetrics)
        r.(allMetrics{m}) = NaN;
    end
    for m = 1:nExpected
        r.(mNames{m}) = metricVals(m);
    end
    r.N = N;

    C{end+1} = r; %#ok<AGROW>
end

%% ─── 5. struct array → table ──────────────────────────────────────────
if isempty(C)
    T = table();
else
    T = struct2table([C{:}]);
    % Текстові поля → string (для зручного == порівняння)
    strCols = {'fig','statsType','pair','algo','sample','example', ...
               'phase','element','component'};
    for s = 1:numel(strCols)
        if iscell(T.(strCols{s}))
            T.(strCols{s}) = string(T.(strCols{s}));
        end
    end
end

end
