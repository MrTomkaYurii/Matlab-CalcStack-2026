function n = make_fig7_mueller(FIG)
% MAKE_FIG7_MUELLER  Рисунок 7 у статтю: УСЯ матриця Мюллера на ОДНОМУ
%   рисунку — |f_ik| та arg(f_ik) усіх 16 елементів, для ОБОХ фазових
%   вікон (блоки згори вниз). Один файл на комбінацію
%   варіант x зразок x приклад x кольоровий режим.
%
%   Тека:  FIG.out.root\Fig7\<mode>\<fmt>\
%   Файл:  Fig7.mueller.<variant>.<sampleTag>.ex<N>.<mode>.<ext>
%
%   ОБСЯГ — cfg_figures.m, секція FIG.fig07.* (зразки / приклади / варіанти).
%   Пер-фігурні параметри оформлення — FIG.fig07.params.* (deep-merge).
%
%       make_fig7_mueller            % бере cfg_figures()
%       make_fig7_mueller(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end
FIG = apply_fig_params(FIG, 'fig07');
C = FIG.fig07;

fprintf('=== Fig7 (повна матриця Мюллера, один рисунок) ===\n');
n = 0;
for si = 1:numel(C.samples)
    sName = C.samples{si};  sTag = sample_tag(FIG, sName);
    for xi = 1:numel(C.examples)
        ex = C.examples{xi};
        for vi = 1:numel(C.variants)
            v = C.variants{vi};

            winData = cell(1, numel(FIG.phase));  ok = true;
            for w = 1:numel(FIG.phase)
                try
                    winData{w} = tp_paper_read(FIG, sName, ex, v, FIG.phase(w).glob);
                catch ME
                    fprintf(2, '  [skip] Fig7 / %s / %s / %s / w%d : %s\n', ...
                        sName, ex, v.tag, w, ME.message);
                    ok = false; break;
                end
            end
            if ~ok; continue; end

            for mi = 1:numel(FIG.color.modes)
                mode = FIG.color.modes{mi};
                Fm = FIG;
                Fm.color.modMap = FIG.color.maps.(mode).mod;
                Fm.color.argMap = FIG.color.maps.(mode).arg;
                figH = render_mueller_grid(winData, Fm);
                outDir = fullfile(FIG.out.root, 'Fig7', mode);
                exT = 'ex';
                if isfield(FIG,'exampleTag') && ~isempty(FIG.exampleTag); exT = FIG.exampleTag; end
                base = sprintf('Fig7.mueller.%s.%s.%s%s.%s', v.tag, sTag, exT, ex, mode);
                fig_export(figH, outDir, base, FIG);
                close(figH);
                n = n + 1;
                fprintf('  [ok] Fig7\\%s\\%s\n', mode, base);
            end
        end
    end
end
fprintf('=== Fig7: %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end

% ----------------------------------------------------------------------
function tag = sample_tag(FIG, sName)
i = find(strcmp(FIG.sampleTag(:,1), sName), 1);
if isempty(i); tag = regexprep(lower(sName), '\s+', '-'); else; tag = FIG.sampleTag{i,2}; end
end
