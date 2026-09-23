function scan_september_data_health()
% SCAN_SEPTEMBER_DATA_HEALTH  Перевіряє КОЖЕН зразок/приклад у новому
%   'C:\September 2026-Results\Зразки - нові (серпень 2026) mat' на той
%   самий "битий кадр" дефект, що й раніше в august2026 (ex_90.mat /
%   ey_0.mat тощо — дійсні/нульові замість комплексних). Не покладається
%   на стару пам'ять (інша тека, дані могли змінитись) — сканує напряму.

matRoot = 'C:\September 2026-Results\Зразки - нові (серпень 2026) mat';
samples = {'Серце','Мяз живота','Мозг'};
examples = {'1','2','3'};
states = {'0','45','90','135','liv','prav'};

fprintf('%-14s %-4s  %s\n', 'Зразок','Прикл','статус (биті канали)');
fprintf('%s\n', repmat('-',1,70));

for s = 1:numel(samples)
    for e = 1:numel(examples)
        d = fullfile(matRoot, samples{s}, examples{e}, 'mat');
        if ~isfolder(d)
            fprintf('%-14s %-4s  [немає теки mat]\n', samples{s}, examples{e});
            continue;
        end
        bad = {};
        for st = 1:numel(states)
            for pref = {'ex_','ey_'}
                f = fullfile(d, sprintf('%s%s.mat', pref{1}, states{st}));
                if ~isfile(f)
                    bad{end+1} = sprintf('%s%s(MISSING)', pref{1}, states{st}); %#ok<AGROW>
                    continue;
                end
                S = load(f);
                vn = fieldnames(S);
                X = S.(vn{1});
                if isreal(X)
                    bad{end+1} = sprintf('%s%s', pref{1}, states{st}); %#ok<AGROW>
                end
            end
        end
        if isempty(bad)
            fprintf('%-14s %-4s  ЧИСТИЙ (усі 12 каналів комплексні)\n', samples{s}, examples{e});
        else
            fprintf('%-14s %-4s  БИТИЙ: %s\n', samples{s}, examples{e}, strjoin(bad, ', '));
        end
    end
end
end
