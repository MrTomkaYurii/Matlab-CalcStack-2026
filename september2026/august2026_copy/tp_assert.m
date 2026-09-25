function tp_assert(cond, fmt, varargin)
% TP_ASSERT  Єдиний стиль перевірки передумов.
%   Якщо cond хибна — кидає ЗРОЗУМІЛУ помилку з префіксом TwoPoint:precondition.
%   Не глушить помилки: їх ловить зовнішня обгортка (оркестратор/диспетчер/стадія)
%   разом із контекстом (зразок/елемент/стадія).
%
%   Приклад:  tp_assert(N >= 2, 'crop.size замалий: %d', N);
if ~cond
    error('TwoPoint:precondition', fmt, varargin{:});
end
end
