function [f, p] = tp_cut_psd(cut)
% (винесено без змін з viz_acf_cuts.m, локальна cutPSD -- спільне з tp_stats_element)
% PSD 1D-перерізу ACF = |FFT(ACF)| (Wiener–Khinchin); лишаємо додатні частоти.
L = numel(cut);
p = abs(fft(ifftshift(cut)));      % ACF центрований у середині -> ifftshift
f = (0:L-1)/L;
pos = 2:floor(L/2);                % пропускаємо DC для log-log
f = f(pos);  p = p(pos) + eps;
end
