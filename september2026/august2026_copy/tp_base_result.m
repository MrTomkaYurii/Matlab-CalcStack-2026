function R = tp_base_result(algorithm, sampleName, CFG)
% TP_BASE_RESULT  Порожня канонічна структура результату для всіх алгоритмів.
%   Поля заповнює алгоритм, а читає tp_visualize:
%       R.algorithm            char
%       R.sample               char
%       R.elements             cellstr імен f_ik
%       R.dirs                 cellstr напрямів (напр. {'OX_d1','OY_d1',...})
%       R.data.(DIR).(elem)    struct('cplx','mod','arg')  2D-масиви
%       R.axes.(DIR)           struct('x',vec,'y',vec)     значення поділок осей
%       R.label.(DIR)          struct('x',str,'y',str)     англ. підписи осей
%       R.params               параметри конкретного алгоритму

R = struct();
R.algorithm = algorithm;
R.sample    = sampleName;
R.elements  = CFG.elements;
R.dirs      = {};
R.data      = struct();
R.axes      = struct();
R.label     = struct();
R.params    = struct();
end
