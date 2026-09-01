function explore_mat_data(matDir)
% EXPLORE_MAT_DATA  Швидке дослідження .mat-файлів з "реконструйованими
%   комплексними амплітудами" (за замовчуванням C:\August 2026-Results\mat).
%   Самодостатній, нічого із проєкту не використовує — можна запускати одразу.
%
%   Для КОЖНОГО файлу показує:
%     - які змінні всередині, їхній розмір і тип (whos-стиль);
%     - чи значення КОМПЛЕКСНІ (isreal) чи ні;
%     - якщо комплексні: діапазони |X| (модуль) та arg(X) (фаза), і окремо Re/Im;
%     - якщо дійсні: просто діапазон значень;
%     - чи є NaN/Inf.
%
%   Використання:
%       explore_mat_data                      % бере C:\August 2026-Results\mat
%       explore_mat_data('D:\інша\тека')       % або власний шлях

if nargin < 1
    matDir = 'C:\August 2026-Results\mat';
end

files = dir(fullfile(matDir, '*.mat'));
if isempty(files)
    error('explore_mat_data:noFiles', 'Немає .mat файлів у %s', matDir);
end

fprintf('=== Дослідження .mat файлів у %s ===\n', matDir);
fprintf('Знайдено файлів: %d\n\n', numel(files));

for k = 1:numel(files)
    fname = fullfile(matDir, files(k).name);
    fprintf('--- %s (%.2f MB) ---\n', files(k).name, files(k).bytes/1e6);

    try
        info = whos('-file', fname);
    catch ME
        fprintf('  !! не вдалось прочитати список змінних: %s\n\n', ME.message);
        continue;
    end
    if isempty(info)
        fprintf('  (файл не містить змінних)\n\n');
        continue;
    end

    for v = 1:numel(info)
        fprintf('  змінна: %-15s розмір: %-15s клас: %-10s байт: %d\n', ...
                info(v).name, mat2str(info(v).size), info(v).class, info(v).bytes);
    end

    try
        S = load(fname);
    catch ME
        fprintf('  !! не вдалось завантажити файл: %s\n\n', ME.message);
        continue;
    end

    vn = fieldnames(S);
    for v = 1:numel(vn)
        X = S.(vn{v});
        if ~isnumeric(X)
            fprintf('  [%s] не числовий тип (%s) — пропускаю статистику\n', vn{v}, class(X));
            continue;
        end

        isCplx = ~isreal(X);
        fprintf('  [%s] розмір=%s  isreal=%d  numel=%d\n', vn{v}, mat2str(size(X)), isreal(X), numel(X));

        if isCplx
            A = abs(X); P = angle(X);
            fprintf('    |X| (модуль):  min=%.4g  max=%.4g  mean=%.4g\n', min(A(:)), max(A(:)), mean(A(:)));
            fprintf('    arg(X) [rad]:  min=%.4g  max=%.4g  mean=%.4g\n', min(P(:)), max(P(:)), mean(P(:)));
            fprintf('    Re(X):  min=%.4g  max=%.4g   Im(X):  min=%.4g  max=%.4g\n', ...
                    min(real(X(:))), max(real(X(:))), min(imag(X(:))), max(imag(X(:))));
        else
            fprintf('    значення:  min=%.4g  max=%.4g  mean=%.4g\n', ...
                    min(X(:)), max(X(:)), mean(X(:)));
        end

        nNaN = sum(isnan(X(:)));
        nInf = sum(isinf(X(:)));
        if nNaN > 0, fprintf('    !! містить NaN: %d\n', nNaN); end
        if nInf > 0, fprintf('    !! містить Inf: %d\n', nInf); end
    end
    fprintf('\n');
end

fprintf('=== Готово ===\n');
end
