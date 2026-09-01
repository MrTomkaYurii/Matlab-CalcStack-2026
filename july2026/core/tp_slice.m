function S = tp_slice(IMG, rr, cc)
% TP_SLICE  Вирізає кожен канал вкладеної структури зображень за рядками rr,
%   стовпцями cc. Зберігає розкладку IMG.(inPol).(analyzer), тож результат
%   можна одразу подавати в tp_fik_pair як набір "точки 1" або "точки 2".

pols = fieldnames(IMG);
S = struct();
for i = 1:numel(pols)
    ch = fieldnames(IMG.(pols{i}));
    for j = 1:numel(ch)
        S.(pols{i}).(ch{j}) = IMG.(pols{i}).(ch{j})(rr, cc);
    end
end
end
