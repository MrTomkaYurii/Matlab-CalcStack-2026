function t = tp_an_elem_tex(elem)
% TP_AN_ELEM_TEX  Ім'я величини Кроку B у TeX для заголовків рисунків аналітики
%   (позначення точно як у формулах: LB_{0,90}, LB_{45,135}, CB, \rho, LB).
switch elem
    case 'LB_0_90',   t = 'LB_{0,90}';
    case 'LB_45_135', t = 'LB_{45,135}';
    case 'rho',       t = '\rho';
    otherwise,        t = strrep(elem, '_', '\_');
end
end
