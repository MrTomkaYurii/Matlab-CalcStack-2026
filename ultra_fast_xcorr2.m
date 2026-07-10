function [acf_magnitude, M_acf, N_acf] = ultra_fast_xcorr2(magnitude_centered)
   % === МАКСИМАЛЬНАЯ ОПТИМИЗАЦИЯ ДЛЯ 16-ПОТОЧНОГО CPU ===
   
   maxNumCompThreads(16);
   magnitude_centered = single(magnitude_centered);
   [M, N] = size(magnitude_centered);
   
   opt_M = 2^nextpow2(2*M-1);
   opt_N = 2^nextpow2(2*N-1);
   
   magnitude_padded = zeros(opt_M, opt_N, 'single');
   magnitude_padded(1:M, 1:N) = magnitude_centered;
   
   persistent is_optimized
   if isempty(is_optimized)
       fftw('planner', 'measure');
       dummy = randn(opt_M, opt_N, 'single');
       fft2(dummy); ifft2(dummy);
       is_optimized = true;
   end
   
   magnitude_fft = fft2(magnitude_padded);
   power_spectrum = magnitude_fft .* conj(magnitude_fft);
   acf_full = ifft2(power_spectrum);
   
   acf_temp = real(acf_full(1:2*M-1, 1:2*N-1));
   
   % ЦЕНТРИРОВАНИЕ - пик будет в центре как в xcorr2
   acf_magnitude = fftshift(acf_temp);
   
   % Вернуть размеры АКФ
   [M_acf, N_acf] = size(acf_magnitude);
end