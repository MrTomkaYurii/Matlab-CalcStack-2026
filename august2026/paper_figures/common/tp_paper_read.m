function D = tp_paper_read(FIG, sampleName, exampleName, variant, phaseGlob)
% TP_PAPER_READ  Читає ОДИН result.mat (один зразок/приклад/варіант/фазове
%   вікно) і повертає mod/arg-карти всіх 16 елементів + осі. Нічого не
%   рахує. Використовується render-конвеєром рисунків у статтю.
%
%   D.data        : struct f11..f44, кожен .mod / .arg (2D double, з NaN)
%   D.ax.x, D.ax.y: вектори координат (px). orthogonal -> 1..N;
%                   generalized -> -M..M (вектор рознесення)
%   D.file        : шлях до прочитаного result.mat (для діагностики/таблиці)
%
%   variant : struct('tag',..,'algo','generalized'|'orthogonal','dir',''|'OX'|'OY')

sampleDir = fullfile(FIG.data.saveRoot, sampleName, exampleName);
pd = dir(fullfile(sampleDir, phaseGlob));
pd = pd([pd.isdir]);
assert(~isempty(pd), 'tp_paper_read: не знайдено теку "%s" у %s', phaseGlob, sampleDir);
phaseDir = fullfile(pd(1).folder, pd(1).name);

stepFolder = sprintf('step_%d', FIG.data.step);
switch lower(variant.algo)
    case 'generalized'
        rf = fullfile(phaseDir, 'generalized', stepFolder, 'result.mat');
        assert(isfile(rf), 'tp_paper_read: немає %s', rf);
        S = load(rf, 'R');  R = S.R;
    case 'orthogonal'
        assert(any(strcmpi(variant.dir, {'OX','OY'})), ...
            'tp_paper_read: для orthogonal потрібен variant.dir = OX або OY');
        rf = fullfile(phaseDir, 'orthogonal', upper(variant.dir), stepFolder, 'result.mat');
        assert(isfile(rf), 'tp_paper_read: немає %s', rf);
        S = load(rf, 'Rd');  R = S.Rd;
    case 'polar'
        % ЄДИНА карта PERP (Σ_θ f) або осьові зрізи OX/OY того самого скану;
        % розкладка тек як в orthogonal (змінна Rd), крок = радіус rho.
        assert(any(strcmpi(variant.dir, {'PERP','OX','OY'})), ...
            'tp_paper_read: для polar потрібен variant.dir = PERP, OX або OY');
        rf = fullfile(phaseDir, 'polar', upper(variant.dir), stepFolder, 'result.mat');
        assert(isfile(rf), 'tp_paper_read: немає %s', rf);
        S = load(rf, 'Rd');  R = S.Rd;
    otherwise
        error('tp_paper_read: невідомий algo "%s"', variant.algo);
end

d = R.dirs{1};
D.data = R.data.(d);          % f11..f44 -> .mod/.arg/.cplx
D.ax.x = R.axes.(d).x(:).';
D.ax.y = R.axes.(d).y(:).';
D.file = rf;

% усунути довільний масштаб реконструйованих полів (m_ik = f_ik / медіана|f_11|);
% лише для рисунків, сирий result.mat не чіпається. Деталі — tp_paper_normalize.m
key = sprintf('%s|%s|%s', sampleName, exampleName, variant.tag);
D = tp_paper_normalize(D, key, FIG);
end
