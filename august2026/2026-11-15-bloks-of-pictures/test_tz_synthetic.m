function test_tz_synthetic(outRoot, ids)
% TEST_TZ_SYNTHETIC  Перевірка всього конвеєра ТЗ без справжніх даних:
%   створює штучні result.mat тієї самої структури (XY і orthogonal/OY, вікна 0–2π, 0–1.75π,
%   0–1.25π; у Мозку f_i1, f_i2 порожні, як у справжніх даних) і запускає run_tz_blocks.
%
%       test_tz_synthetic(tempdir)              % блоки 1, 3, 5
%       test_tz_synthetic('D:\tmp', {'1'})
if nargin < 1; outRoot = fullfile(tempdir, 'tz_synthetic'); end
if nargin < 2; ids = {'1','3','5'}; end
here = fileparts(mfilename('fullpath'));
addpath(here);
saveRoot = fullfile(outRoot, 'data');
N = 200;  rng(7);                                 % 200 px: CWT дістає масштабу a = 55 (на 400 px — до ~140)
wins = [1 2 4];                                   % phase_01 (2π), phase_02 (1.75π), phase_04 (1.25π)
for smp = {'Мяз живота', 'Мозг'}
    for ex = {'1','2','3'}
        for k = wins
            w = 2 - 0.25*(k-1);
            ph = fullfile(saveRoot, smp{1}, ex{1}, sprintf('phase_%02d_[0-%.2fpi]', k, w));
            R = fake('XY', N, strcmp(smp{1}, 'Мозг'), w);
            save_mat(fullfile(ph, 'XY', 'step_1'), 'R', R);
            Rd = fake('OY', N, strcmp(smp{1}, 'Мозг'), w);
            save_mat(fullfile(ph, 'orthogonal', 'OY', 'step_1'), 'Rd', Rd);
        end
    end
end
run_tz_blocks(ids, struct('saveRoot', saveRoot, 'out', fullfile(outRoot, 'out'), 'overwrite', true));
end

function R = fake(d, N, brain, w)
R.dirs = {d};
g = exp(-((-6:6).^2) / 8);  g = g' * g;
for i = 1:4
    for k = 1:4
        m = conv2(randn(N + 12), g, 'valid');  m = abs(m(1:N, 1:N)) * 1e-6;
        a = mod(conv2(randn(N + 12), g, 'valid'), 2*pi);  a = a(1:N, 1:N);
        mask = a <= w*pi;                          % фазове вікно -> поза ним NaN
        m(~mask) = NaN;  a(~mask) = NaN;
        if brain && k <= 2; m(:) = NaN; a(:) = NaN; end
        e = sprintf('f%d%d', i, k);
        R.data.(d).(e) = struct('mod', m, 'arg', a, 'cplx', m .* exp(1i*a));
    end
end
R.axes.(d) = struct('x', 1:N, 'y', 1:N);
end

function save_mat(dirp, name, v)
if ~exist(dirp, 'dir'); mkdir(dirp); end
S.(name) = v; %#ok<STRNU>
save(fullfile(dirp, 'result.mat'), '-struct', 'S');
end
