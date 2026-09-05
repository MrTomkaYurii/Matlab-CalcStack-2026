function tf = build_wants(build, figTag, pairKey)
% BUILD_WANTS  Чи входить завдання <figTag> (або <figTag>:<pairKey>) у список
%   FIG.build. 'Fig1' у списку -> ОБИДВІ пари рисунка; 'Fig1:f33f44' -> лише
%   ця пара. Порожній build -> true (нема обмежень).
%
%   Спільне для run_all_figures (які рисунки будувати) і make_stats_table
%   (для яких рисунків рахувати таблиці моментів).

if isempty(build); tf = true; return; end
tf = any(strcmpi(build, figTag));
if ~tf && nargin >= 3 && ~isempty(pairKey)
    tf = any(strcmpi(build, [figTag ':' pairKey]));
end
end
