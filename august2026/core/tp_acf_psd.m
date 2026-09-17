function [acf, psd, lagx, lagy] = tp_acf_psd(Z, method)
% TP_ACF_PSD  2D автокореляція (ACF) і спектральна щільність (PSD) карти Z.
%   Спільний розрахунок для рисунків (4A) та (4B).
%   method:
%     'direct' — ACF = xcorr2 (за визначенням, повільно), PSD = |FFT(ACF)|^2
%     'fast'   — ACF через FFT з нуль-доповненням (== xcorr2, швидко),
%                PSD = періодограма |FFT(поле)|^2
%   NaN заповнюються середнім; поле центрується.
%
%   acf  : нормована 2D ACF (макс = 1), розмір (2M-1)x(2N-1)
%   psd  : 2D PSD (fftshift)
%   lagx, lagy : осі лагів для acf

v = Z;
fin = v(isfinite(v));
if isempty(fin); mu = 0; else; mu = mean(fin); end
v(~isfinite(v)) = mu;
v = v - mu;
[M, N] = size(v);

switch lower(method)
    case 'direct'
        acf = xcorr2(v);
        acf = acf / max(abs(acf(:)) + eps);
        psd = fftshift(abs(fft2(acf)).^2 / numel(acf));
    otherwise   % 'fast'
        Mp = 2*M - 1;  Np = 2*N - 1;             % нуль-доповнення => лінійна ACF
        F   = fft2(v, Mp, Np);
        acf = fftshift(real(ifft2(abs(F).^2))); % ідентично xcorr2(v)
        acf = acf / max(abs(acf(:)) + eps);
        psd = fftshift(abs(fft2(v)).^2 / (M*N));
end
acf = max(acf, 0);   % ACF у [0,1], без відʼємних (PSD рахується до обрізання)
[Ma, Na] = size(acf);
lagx = (-(Na-1)/2 : (Na-1)/2);
lagy = (-(Ma-1)/2 : (Ma-1)/2);
end
