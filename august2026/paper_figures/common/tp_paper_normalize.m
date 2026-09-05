function D = tp_paper_normalize(D, key, FIG)
% TP_PAPER_NORMALIZE  Прибирає ДОВІЛЬНИЙ масштаб реконструйованих полів із карт
%   f_ik ПЕРЕД побудовою рисунків статті. Використовується ЛИШЕ конвеєром
%   paper_figures — сирий result.mat і головний пайплайн НЕ чіпаються.
%
%   Чому: реконструйовані Ex,Ey мають довільний масштаб |E| ~ 1e-3 (нормування
%   відновлення полів із голограм — поза цим кодом). Елементи f_ik білінійні за
%   полем -> |f_ik| ~ |E|^2 ~ 1e-6. Ділимо ВСІ 16 елементів на скаляр — медіану
%   |f_11| — тобто m_ik = f_ik / f_11 (скалярна нормалізація матриці Мюллера).
%   Фаза arg НЕ міняється (ділення на додатне число). Множник спільний для всіх
%   елементів, тож крос-канальні співвідношення збережені.
%
%   Опорний масштаб КЕШУЄТЬСЯ per key: перше звернення (найширше фазове вікно
%   цього зразка/прикладу/варіанта) задає масштаб, решта вікон діляться на
%   нього -> реальні відмінності між вікнами збережені.
%
%       D = tp_paper_normalize(D, 'Серце|2|generalized', FIG)
%       tp_paper_normalize('reset')          % очистити кеш (між прогонами)
%
%   D   : структура від tp_paper_read (.data.f11..f44 з .mod/.arg/.cplx)
%   key : 'sample|example|variant'
%   FIG : cfg_figures();  FIG.data.normalize = true|false  (типово true)

persistent REF
if isempty(REF); REF = containers.Map('KeyType','char','ValueType','double'); end

if nargin == 1 && (ischar(D) || isstring(D)) && strcmpi(D, 'reset')
    REF = containers.Map('KeyType','char','ValueType','double');
    D = [];  return;
end

if isfield(FIG,'data') && isfield(FIG.data,'normalize') && ~FIG.data.normalize
    return;                                  % 'сирі' значення, як у result.mat
end

if ~isKey(REF, key)
    v = D.data.f11.mod;
    v = v(isfinite(v) & v > 0);
    if isempty(v); REF(key) = 1; else; REF(key) = median(v); end
end
s = REF(key);
if ~(isfinite(s) && s > 0); return; end

els = fieldnames(D.data);
for e = 1:numel(els)
    D.data.(els{e}).mod = D.data.(els{e}).mod / s;
    if isfield(D.data.(els{e}), 'cplx')
        D.data.(els{e}).cplx = D.data.(els{e}).cplx / s;
    end
end
D.normScale = s;                             % множник (для діагностики/таблиць)
end
