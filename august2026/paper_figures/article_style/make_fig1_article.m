function n = make_fig1_article(~, scope)
% MAKE_FIG1_ARTICLE  Fig1 "як у статті" — обгортка: make_fig_article('Fig1', scope).
%   Перший аргумент (FIG) лишено для сумісності — ігнорується.
if nargin < 2; scope = struct(); end
n = make_fig_article('Fig1', scope);
end
