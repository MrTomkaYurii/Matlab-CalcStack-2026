function [SC1, SC2, SC3, SC4] = tp_sc_vector(Ex1, Ey1, Ex2, Ey2)
% TP_SC_VECTOR  Комплексний двоточковий вектор Стокса, стаття рівн. (10):
%   SC1 = Ex1*.Ex2 + Ey1*.Ey2      SC2 = Ex1*.Ex2 - Ey1*.Ey2
%   SC3 = Ex1*.Ey2 + Ey1*.Ex2      SC4 = i(Ey1*.Ex2 - Ex1*.Ey2)
%   Спряження — у точці 1. Аргументи — комплексні масиви однакового розміру
%   (або сумісні для broadcasting, як у tp_algo_generalized_batch).
%   Єдине джерело формули для tp_fik_pair і пакетної версії.

cx1 = conj(Ex1);  cy1 = conj(Ey1);
XX = cx1 .* Ex2;  YY = cy1 .* Ey2;
XY = cx1 .* Ey2;  YX = cy1 .* Ex2;
SC1 = XX + YY;
SC2 = XX - YY;
SC3 = XY + YX;
SC4 = 1i * (YX - XY);
end
