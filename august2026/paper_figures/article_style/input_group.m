function [sub, missing] = input_group(W)
% INPUT_GROUP  До якої верхньої теки результату належить зразок/приклад:
%   'Відсутні вхідні канали' — хоча б один з 16 елементів f_ik не має жодного значення в усіх
%                              фазових вікнах (порожні вхідні канали ex_90 / ey_0: Серце 1, Мозг 1–3);
%   'Усі вхідні канали'      — усі 16 елементів пораховані.
%   W : cell з tp_paper_read (кожен .data.f11..f44 з .mod)
missing = {};
for i = 1:4
    for k = 1:4
        e = sprintf('f%d%d', i, k);
        if all(cellfun(@(D) ~any(isfinite(D.data.(e).mod(:))), W)); missing{end+1} = e; end %#ok<AGROW>
    end
end
G = input_groups();
sub = G{1 + isempty(missing)};
end
