function [Rw, keptFrac] = tp_phase_window_result(R, CFG, k)
% TP_PHASE_WINDOW_RESULT  Застосовує tp_phase_window_element до КОЖНОГО
%   елемента КОЖНОГО напряму канонічного результату R (R.dirs, R.data.
%   (dir).(elem) = struct('cplx','mod','arg')) — тобто одне й те саме k-те
%   фазове вікно, але окремо порахований критерій (власний arg) для
%   кожного елемента. Використовується ПІСЛЯ повного (немаскованого)
%   розрахунку алгоритму, у циклі по k (run_TwoPoint_Pipeline.m,
%   run_TwoPoint_FillMissing.m).
%
%   [Rw, keptFrac] = tp_phase_window_result(R, CFG, k)
%       Rw       : копія R з .cplx/.mod/.arg замаскованими поза вікном k
%                  (окремо для кожного елемента кожного напряму)
%       keptFrac : struct(dir).(elem) = частка збережених пікселів (QC)

Rw = R;
keptFrac = struct();
for di = 1:numel(R.dirs)
    dirName = R.dirs{di};
    elems = fieldnames(R.data.(dirName));
    for e = 1:numel(elems)
        elem = elems{e};
        [Se, info] = tp_phase_window_element(R.data.(dirName).(elem), CFG, k);
        Rw.data.(dirName).(elem) = Se;
        keptFrac.(dirName).(elem) = info.keptFrac;
    end
end
end
