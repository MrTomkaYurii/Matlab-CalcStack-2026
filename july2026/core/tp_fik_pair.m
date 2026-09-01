function [F, DBG] = tp_fik_pair(A1, A2)
% TP_FIK_PAIR  Комплексні двоточкові елементи матриці Мюллера f_ik для пар точок.
%   Векторизоване єдине джерело формул з документа "Матрицы Мюллера":
%     (1)      |Ex| = sqrt(I0deg),  |Ey| = sqrt(I90deg)
%              delta = atan2(I_prav - I_liv, I_45 - I_135)
%     (6)-(13) a_i, b_i для i = 1..4  (на кожне освітлення 0,45,90,RC)
%     розд.4   f_ik = комбінація чотирьох освітлень
%
%   A1, A2 : вкладені структури зображень (точка 1 / точка 2), кожна з полями
%            .in0 .in45 .in90 .inRC, у кожному .I0 .I45 .I90 .I135 .Iliv .Iprav
%            Усі канали — однакового розміру 2D-масиви (сітка пари).
%
%   F : структура з комплексними полями f11..f44 (рядок i = a_i/b_i, стовпець k = комбо освітлень).

inPols = {'in0','in45','in90','inRC'};

% -- передумови ------------------------------------------------------
tp_assert(isstruct(A1) && isstruct(A2), 'tp_fik_pair: A1 і A2 мають бути структурами');
tp_assert(all(isfield(A1, inPols)) && all(isfield(A2, inPols)), ...
    'tp_fik_pair: відсутні стани освітлення (потрібні in0,in45,in90,inRC)');
tp_assert(isequal(size(A1.in0.I0), size(A2.in0.I0)), ...
    'tp_fik_pair: розміри точки 1 і точки 2 не збігаються');

% a{i}.(inPol) та b{i}.(inPol), i = 1..4
a = {struct(),struct(),struct(),struct()};
b = {struct(),struct(),struct(),struct()};

for p = 1:numel(inPols)
    P  = inPols{p};
    S1 = A1.(P);  S2 = A2.(P);

    % (1) амплітуди й фази в обох точках
    % інтенсивність фізично >= 0; max(.,0) захищає амплітуду від комплексних
    % значень, якщо у даних трапилися відʼємні інтенсивності (шум/фон)
    Ex1 = sqrt(max(S1.I0,0));  Ex2 = sqrt(max(S2.I0,0));
    Ey1 = sqrt(max(S1.I90,0)); Ey2 = sqrt(max(S2.I90,0));
    d1  = atan2(S1.Iprav - S1.Iliv, S1.I45 - S1.I135);
    d2  = atan2(S2.Iprav - S2.Iliv, S2.I45 - S2.I135);

    dd = d2 - d1;
    % (6)-(13)
    a{1}.(P) =  Ex1.*Ex2 + Ey1.*Ey2.*cos(dd);
    b{1}.(P) =  Ey1.*Ey2.*sin(dd);
    a{2}.(P) =  Ex1.*Ex2 - Ey1.*Ey2.*cos(dd);
    b{2}.(P) = -Ey1.*Ey2.*sin(dd);
    a{3}.(P) =  Ex1.*Ey2.*cos(d2) + Ex2.*Ey1.*cos(d1);
    b{3}.(P) =  Ex1.*Ey2.*sin(d2) - Ex2.*Ey1.*sin(d1);
    a{4}.(P) =  Ex1.*Ey2.*sin(d2) + Ex2.*Ey1.*sin(d1);
    b{4}.(P) =  Ex1.*Ey2.*cos(d2) - Ex2.*Ey1.*cos(d1);

    if nargout > 1   % проміжні величини для діагностики (test/)
        DBG.perPol.(P) = struct('Ex1',Ex1,'Ex2',Ex2,'Ey1',Ey1,'Ey2',Ey2,'d1',d1,'d2',d2);
    end
end

% розд.4 : 16 комплексних елементів Мюллера
F = struct();
for i = 1:4
    A0  = a{i}.in0;  B0  = b{i}.in0;
    A45 = a{i}.in45; B45 = b{i}.in45;
    A90 = a{i}.in90; B90 = b{i}.in90;
    ARC = a{i}.inRC; BRC = b{i}.inRC;

    Asum = A0 + A90;  Bsum = B0 + B90;
    F.(sprintf('f%d1',i)) = 0.5*( Asum + 1i*Bsum);
    F.(sprintf('f%d2',i)) = 0.5*( Asum - 1i*Bsum);
    F.(sprintf('f%d3',i)) = (A45 - Asum) + 1i*(B45 - Bsum);
    F.(sprintf('f%d4',i)) = (ARC - Asum) + 1i*(BRC - Bsum);
end

if nargout > 1
    DBG.pols = inPols;   % {'in0','in45','in90','inRC'}
    DBG.a = a;           % a{i}.(inPol), i=1..4  (реальні складові)
    DBG.b = b;           % b{i}.(inPol), i=1..4
    DBG.F = F;
end
end
