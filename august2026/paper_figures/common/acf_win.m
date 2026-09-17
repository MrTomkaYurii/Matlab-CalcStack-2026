function w = acf_win(FIG, cfgKey, variant)
% ACF_WIN  Спільне піввікно лагів (px) АКФ для групи (пара елементів × алгоритм).
%   Одне число на всі панелі цієї трійки FigN — усі зразки/приклади/фазові
%   вікна/елементи/mod-arg на АБСОЛЮТНО однаковій сітці лагів. Між алгоритмами
%   вікно РІЗНЕ (XY корелює на кілька px, generalized — на десятки).
%
%   w = clamp( winK * Lref , winMin , winMax ),  де
%     Lref = найбільша ФІЗИЧНА півширина серед панелей групи
%            (визначена і L < winDegen * розмір_карти; майже-сталі карти,
%             де АКФ не спадає, у розрахунок не входять).
%
%   Півширина — з повної 2D-АКФ (paper_prep), як на маркерах рисунка.
%   Мемоізується на "<cfgKey>|<algoTag>". Скид раз на прогін: acf_win('reset').

persistent CACHE
if nargin == 1 && (ischar(FIG) || isstring(FIG)) && strcmpi(FIG, 'reset')
    CACHE = [];  return;
end
if isempty(CACHE); CACHE = containers.Map('KeyType','char','ValueType','any'); end
key = sprintf('%s|%s', cfgKey, variant.tag);
if isKey(CACHE, key); w = CACHE(key); return; end

here = fileparts(mfilename('fullpath'));
addpath(here, fileparts(here));

a = FIG.acf;
K     = getf(a,'winK',    3);
wmin  = getf(a,'winMin',  20);
wmax  = getf(a,'winMax',  200);
degen = getf(a,'winDegen',0.20);

C = FIG.(cfgKey);  elems = C.elems;
Lref = 0;  maxLag = inf;
for si = 1:numel(C.samples)
    for xi = 1:numel(C.examples)
        for pw = 1:numel(FIG.phase)
            try
                D = tp_paper_read(FIG, C.samples{si}, C.examples{xi}, variant, FIG.phase(pw).glob);
            catch
                continue
            end
            Nmap = min(numel(D.ax.x), numel(D.ax.y));
            wd   = paper_prep({D}, elems, 'acf', FIG);
            for e = 1:numel(elems)
                for comp = {'mod','arg'}
                    P = wd{1}.prep.(elems{e}).(comp{1});
                    maxLag = min(maxLag, max(abs(P.x)));
                    L = P.Lcorr;
                    if isfinite(L) && L > 0 && L < degen * Nmap
                        Lref = max(Lref, L);           % робастний: без вироджених
                    end
                end
            end
        end
    end
end

if Lref > 0
    w = ceil(K * Lref);
else
    w = wmin;
end
w = min(max(w, wmin), wmax);
if isfinite(maxLag); w = min(w, maxLag); end
CACHE(key) = w;
end

% ----------------------------------------------------------------------
function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)); v = s.(f); else; v = d; end
end
