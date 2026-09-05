function n = make_grid_pair(FIG, cfgKey, figTag, kind)
% MAKE_GRID_PAIR  Спільний двигун Fig1/Fig2/Fig3 (august2026\paper_figures\
%   common\): будує рисунок сітки 4x4 для КОЖНОЇ комбінації зразок x приклад
%   x варіант(generalized/OX/OY) x кольоровий режим (color/gray), зберігає
%   у всіх форматах (кожен формат — у своїй підтеці).
%
%   cfgKey : напр. 'fig02_f33f44'  — підсекція FIG з ОБСЯГОМ
%            (.elems/.elemTex/.samples/.examples/.variants; див. cfg_figures.m)
%   figTag : 'Fig1' | 'Fig2' | 'Fig3'  (префікс імені файлу і назва підтеки)
%   kind   : 'raw' | 'acf' | 'psd'  — що показувати (Fig1/Fig2/Fig3)
%
%   Тека:  FIG.out.root\<figTag>\<mode>\<fmt>\
%   Файл:  <figTag>.<e1>-<e2>.<variant>.<sampleTag>.<exampleTag><N>.<mode>.<ext>
%          (exampleTag — FIG.exampleTag, типово 'zrazok': ...heart.zrazok2.color.svg)
%
%   n : скільки рисунків (файл-груп) згенеровано.

here = fileparts(mfilename('fullpath'));   % ...\paper_figures\common
root = fileparts(here);                     % ...\paper_figures (fig_export.m)
addpath(root, here);

FIG = apply_fig_params(FIG, cfgKey);        % пер-фігурні перевизначення .params
C = FIG.(cfgKey);
elems = C.elems;  elemTex = C.elemTex;

n = 0;
for si = 1:numel(C.samples)
    sName = C.samples{si};
    sTag  = sample_tag(FIG, sName);
    for xi = 1:numel(C.examples)
        ex = C.examples{xi};
        for vi = 1:numel(C.variants)
            v = C.variants{vi};

            % сирі карти — ОДИН раз на (зразок,приклад,варіант)
            winData = cell(1, numel(FIG.phase));
            ok = true;
            for w = 1:numel(FIG.phase)
                try
                    winData{w} = tp_paper_read(FIG, sName, ex, v, FIG.phase(w).glob);
                catch ME
                    fprintf(2, '  [skip] %s / %s / %s / %s : %s\n', figTag, sName, ex, v.tag, ME.message);
                    ok = false; break;
                end
            end
            if ~ok; continue; end

            % АКФ/PSD/переріз — ОДИН раз (не залежить від кольору)
            winData = paper_prep(winData, elems, kind, FIG);

            for mi = 1:numel(FIG.color.modes)
                mode = FIG.color.modes{mi};
                Fm = FIG;
                Fm.color.modMap = FIG.color.maps.(mode).mod;
                Fm.color.argMap = FIG.color.maps.(mode).arg;

                figH = render_grid_4x4(elems, elemTex, winData, Fm, kind);

                outDir = fullfile(FIG.out.root, figTag, mode);
                base   = sprintf('%s.%s-%s.%s.%s.%s%s.%s', ...
                    figTag, elems{1}, elems{2}, v.tag, sTag, exTag(FIG), ex, mode);
                fig_export(figH, outDir, base, FIG);
                close(figH);
                n = n + 1;
                fprintf('  [ok] %s\\%s\\%s\n', figTag, mode, base);
            end
        end
    end
end
end

% ----------------------------------------------------------------------
function t = exTag(FIG)
if isfield(FIG,'exampleTag') && ~isempty(FIG.exampleTag); t = FIG.exampleTag; else; t = 'ex'; end
end

% ----------------------------------------------------------------------
function tag = sample_tag(FIG, sName)
i = find(strcmp(FIG.sampleTag(:,1), sName), 1);
if isempty(i)
    tag = regexprep(lower(sName), '\s+', '-');
else
    tag = FIG.sampleTag{i,2};
end
end
