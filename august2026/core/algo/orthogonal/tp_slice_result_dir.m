function Rd = tp_slice_result_dir(R, dirName)
% TP_SLICE_RESULT_DIR  Вирізає з повного результату R (canonical
%   tp_base_result, може містити кілька напрямів/кроків у R.dirs) один-
%   єдиний напрям dirName у той самий канонічний формат (R.dirs={dirName}).
%   Використовується, щоб зберігати result.mat ОКРЕМО в кожній підтеці
%   кроку (orthogonal\OX\step_N\result.mat), а не один спільний файл на
%   весь алгоритм — так само, як уже влаштовано для generalized.

Rd = R;
Rd.dirs  = {dirName};
Rd.data  = struct(dirName, R.data.(dirName));
Rd.axes  = struct(dirName, R.axes.(dirName));
Rd.label = struct(dirName, R.label.(dirName));
if isfield(R,'sep') && isfield(R.sep, dirName)
    Rd.sep = struct(dirName, R.sep.(dirName));
end
end
