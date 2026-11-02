function [F, DBG] = tp_fik_pair(A1, A2)
% TP_FIK_PAIR  Комплексні двоточкові елементи матриці Мюллера f_ik для пар точок.
%   За статтею (ред. 11.2026), рівн. (10), (11), (13) і S2:
%     комплексний двоточковий вектор Стокса (спряження — у точці 1):
%       SC1 = Ex1*.Ex2 + Ey1*.Ey2        SC2 = Ex1*.Ex2 - Ey1*.Ey2
%       SC3 = Ex1*.Ey2 + Ey1*.Ex2        SC4 = i(Ey1*.Ex2 - Ex1*.Ey2)
%     елементи (i = 1..4 — номер SC, k — комбінація освітлень):
%       f_i1 = (SC_i(0)  + SC_i(90))  / 2
%       f_i2 = (SC_i(0)  - SC_i(90))  / 2
%       f_i3 = (SC_i(45) - SC_i(135)) / 2
%       f_i4 = (SC_i(RC) - SC_i(LC))  / 2
%   Поля беруться повністю комплексні (фази обох компонент в обох точках).
%   Старе соглашення "фаза Ex = 0 у кожному пікселі" — CFG.fik.phaseRef = 'x'
%   у tp_load_mat (поля приводяться там, ця функція не змінюється).
%
%   A1, A2 : структури (точка 1 / точка 2) з полями tp_fik_pols()
%            (in0,in45,in90,in135,inRC,inLC), у кожному struct('Ex',..,'Ey',..).
%
%   F : структура з комплексними полями f11..f44.
%   DBG (опц.) : DBG.SC{i}.(inPol) — SC_i для кожного освітлення; DBG.a/DBG.b —
%                їх дійсна/уявна частини (сумісність з fik_scale_diagnostic).

inPols = tp_fik_pols();

tp_assert(isstruct(A1) && isstruct(A2), 'tp_fik_pair: A1 і A2 мають бути структурами');
tp_assert(all(isfield(A1, inPols)) && all(isfield(A2, inPols)), ...
    'tp_fik_pair: відсутні стани освітлення (потрібні %s)', strjoin(inPols, ','));
tp_assert(isequal(size(A1.in0.Ex), size(A2.in0.Ex)), ...
    'tp_fik_pair: розміри точки 1 і точки 2 не збігаються');

SC = {struct(),struct(),struct(),struct()};
for p = 1:numel(inPols)
    P = inPols{p};
    [SC{1}.(P), SC{2}.(P), SC{3}.(P), SC{4}.(P)] = ...
        tp_sc_vector(A1.(P).Ex, A1.(P).Ey, A2.(P).Ex, A2.(P).Ey);
end

F = struct();
for i = 1:4
    S = SC{i};
    F.(sprintf('f%d1',i)) = (S.in0  + S.in90)  / 2;
    F.(sprintf('f%d2',i)) = (S.in0  - S.in90)  / 2;
    F.(sprintf('f%d3',i)) = (S.in45 - S.in135) / 2;
    F.(sprintf('f%d4',i)) = (S.inRC - S.inLC)  / 2;
end

if nargout > 1
    DBG.pols = inPols;
    DBG.SC = SC;
    DBG.a = cellfun(@(s) structfun(@real, s, 'UniformOutput', false), SC, 'UniformOutput', false);
    DBG.b = cellfun(@(s) structfun(@imag, s, 'UniformOutput', false), SC, 'UniformOutput', false);
    DBG.F = F;
end
end
