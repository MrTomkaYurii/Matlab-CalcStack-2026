function R2 = tp_LB_CB_rho_from_result(R, dir)
% TP_LB_CB_RHO_FROM_RESULT  Адаптер Крок A -> Крок B.
%   Бере ГОТОВИЙ результат existing пайплайну (result.mat з
%   core/algo/{orthogonal,generalized,XY}/tp_algo_*.m: R.data.(dir).(f_mn)
%   .cplx — 2D-карта комплексних значень f_mn, вже обчислена tp_fik_pair.m,
%   НЕ перераховується тут) і рахує з неї 5 нових похідних елементів
%   (Крок B: LB_0_90, LB_45_135, CB, rho, LB) як 2D-карти, у ТІЙ САМІЙ
%   формі struct('mod',.,'arg',.,'cplx',.), що й R.data.(dir).(f_mn) —
%   щоб їх можна було напряму подати в existing viz_*.m (viz_maps_hist,
%   viz_block3_contours, ...) без жодних змін тих функцій.
%
%   R   : struct, як повертають tp_algo_orthogonal/tp_algo_generalized/
%         tp_algo_XY (поле R.data.(dir).(elem).cplx для elem = f11..f44)
%   dir : ім'я напряму/кроку в R.dirs (напр. 'step_1', 'OX', 'PERP', ...)
%
%   R2  : struct такої ж форми, як R, але:
%         R2.elements = {'LB_0_90','LB_45_135','CB','rho','LB'}
%         R2.data.(dir).(elem) = struct('mod',.,'arg',.,'cplx',.)
%         R2.algorithm = [R.algorithm '+LB_CB_rho'];  решта полів (sample,
%         axes, label, params) скопійовані з R без змін.

tp_assert(isfield(R,'data') && isfield(R.data, dir), ...
    'tp_LB_CB_rho_from_result: R.data.%s відсутнє', dir);
D = R.data.(dir);
need = {'f23','f32','f24','f42','f34','f43'};
tp_assert(all(isfield(D, need)), ...
    'tp_LB_CB_rho_from_result: R.data.%s мусить містити %s', dir, strjoin(need,','));

OUT = tp_LB_CB_rho( D.f23.cplx, D.f32.cplx, D.f24.cplx, D.f42.cplx, D.f34.cplx, D.f43.cplx );

R2 = R;   % копія метаданих (sample, axes, label, params, dirs, algorithm)
R2.algorithm = [R.algorithm '+LB_CB_rho'];
R2.elements  = {'LB_0_90','LB_45_135','CB','rho','LB'};
R2.data = struct();
R2.data.(dir).LB_0_90   = OUT.LB_0_90;
R2.data.(dir).LB_45_135 = OUT.LB_45_135;
R2.data.(dir).CB        = OUT.CB;
R2.data.(dir).rho       = OUT.rho;
R2.data.(dir).LB        = OUT.LB;
end
