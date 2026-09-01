function tp_visualize(R, CFG)
% TP_VISUALIZE  Будує всі увімкнені подання за ескізом (варфреймами).
%   На кожен напрям/крок:
%       * оглядові сітки 4x4 (усі f_ik)                     — viz_overview
%   На кожен елемент f_ik (комбіновані фігури мод+арг):
%       (1) карти + гістограми        2x2                    — viz_maps_hist
%       (2) контурні карти + 3D       2x2                    — viz_sections
%       (3) вейвлет W(a,b)            2x2                    — viz_wavelet
%   Вироджені елементи (за контролем якості модуля) пропускаються.

% "безпечна" для TeX-заголовків версія R.sample: сирий R.sample лишається
% недоторканим (він використовується для побудови шляхів тек через fullfile
% і МОЖЕ містити '\' у складених іменах "зразок\підтека"); \ і / у ньому
% ламають TeX-інтерпретатор заголовків (сприймаються як керуючі команди),
% тому для показу в тексті замінюємо їх на читабельний роздільник.
sampleDisp = strrep(strrep(R.sample, '\', ' / '), '/', ' / ');

for d = 1:numel(R.dirs)
    dir = R.dirs{d};
    ax  = R.axes.(dir);  lb = R.label.(dir);

    % підпис напряму + рівні тек (напрям і крок окремо)
    if isfield(R,'sep') && isfield(R.sep, dir)
        dirDisp   = sprintf('%s \\Delta=%d px', R.sep.(dir).direction, R.sep.(dir).delta);
        dirLevels = {R.sep.(dir).direction, sprintf('step_%d', R.sep.(dir).delta)};
    else
        dirDisp   = strrep(dir, '_', '\_');
        dirLevels = {dir};                 % узагальнений: 'RHO'
    end
    baseParts = [{R.sample, R.algorithm}, dirLevels];   % тека до рівня кроку
    % МАЛЕНЬКА локальна копія — щоб усередині parfor нижче НЕ звертатись до
    % R.algorithm напряму: будь-яке звернення до поля R змушує MATLAB
    % розсилати кожному воркеру ВСЮ структуру R (з R.data ВСІХ напрямів/кроків,
    % для ортогонального це може бути >1 ГБ) замість лише "нарізаних" Dlist{v}.
    % Саме це спричиняло "Out of Memory during deserialization".
    algoName = R.algorithm;

    % ---- оглядові сітки 4x4 на рівні кроку -------------------------
    if CFG.viz.overview
        ovTitle = sprintf('%s \\cdot %s \\cdot %s', sampleDisp, R.algorithm, dirDisp);
        try
            viz_overview(R, dir, baseParts, ovTitle, CFG);
        catch ME
            fprintf(2, '   [viz fail] %s/%s overview: %s\n', R.algorithm, dir, ME.message);
        end
    end

    % ---- поелементні фігури (розпаралелено по f_ik) ----------------
    % QC-фільтр рахуємо ПОСЛІДОВНО й заздалегідь (дешево), щоб [skip]
    % друкувався по порядку, а важкий побудова графіків ішла в parfor.
    nE = numel(R.elements);
    Dcell = cell(nE,1); okMask = false(1,nE);
    for e = 1:nE
        Dcell{e} = R.data.(dir).(R.elements{e});   % .mod .arg .cplx
        [ok, rM] = tp_validate(Dcell{e}.mod, CFG);
        okMask(e) = ok;
        if ~ok
            fprintf('   [skip] %s/%s/%s: %s\n', R.algorithm, dir, R.elements{e}, rM);
        end
    end
    elemList = R.elements(okMask);
    Dlist    = Dcell(okMask);          % "нарізана" вхідна змінна для parfor —
    nV = numel(elemList);              % кожен воркер отримує ЛИШЕ свій елемент,
                                        % а не всю (важку) структуру R
    useParallel = ~isfield(CFG.viz,'parallel') || CFG.viz.parallel;  % за замовч. увімкнено
    M = 0; if useParallel, M = Inf; end   % M=0 -> послідовно; M=Inf -> усі ядра

    parfor (v = 1:nV, M)
        elem = elemList{v};
        D    = Dlist{v};

        elemTeX = sprintf('f_{%s%s}', elem(2), elem(3));
        acfData = [];
        if CFG.viz.acfPsd || CFG.viz.acfCuts
            % АКФ/PSD спільні для (4A) і (4B) — рахуємо ОДИН раз тут і
            % прокидаємо в обидва модулі через meta.acfData (замість того,
            % щоб кожен модуль незалежно перераховував те саме на елемент).
            method = lower(CFG.acf.method);
            [amod, pmod, lxm, lym] = tp_acf_psd(D.mod, method);
            [aarg, parg, lxa, lya] = tp_acf_psd(D.arg, method);
            acfData = struct( ...
                'method', method, ...
                'mod', struct('acf',amod, 'psd',pmod, 'lagx',lxm, 'lagy',lym), ...
                'arg', struct('acf',aarg, 'psd',parg, 'lagx',lxa, 'lagy',lya));
        end
        meta = struct( ...
            'x', ax.x, 'y', ax.y, 'xlabel', lb.x, 'ylabel', lb.y, ...
            'elemTeX', elemTeX, ...
            'modLabel', sprintf('|%s|', elemTeX), ...
            'argLabel', sprintf('Arg(%s) [rad]', elemTeX), ...
            'titlePrefix', sprintf('%s \\cdot %s \\cdot %s \\cdot %s', ...
                                   sampleDisp, algoName, dirDisp, elemTeX), ...
            'acfData', acfData);
        ctx = struct('parts', {[baseParts, {elem}]}, 'name', elem);

        tag = sprintf('%s/%s/%s', algoName, dir, elem);
        runViz(CFG.viz.mapsHist,    @viz_maps_hist, D, meta, ctx, CFG, tag, 'maps_hist');
        runViz(CFG.viz.surfContour, @viz_sections,  D, meta, ctx, CFG, tag, 'surf_contour');
        runViz(CFG.viz.contour3,    @viz_contour3d, D, meta, ctx, CFG, tag, 'contour3');
        runViz(CFG.viz.wavelet,     @viz_wavelet,   D, meta, ctx, CFG, tag, 'wavelet');
        runViz(CFG.viz.acfPsd,      @viz_acf_psd,   D, meta, ctx, CFG, tag, 'acf_psd');
        runViz(CFG.viz.acfCuts,     @viz_acf_cuts,  D, meta, ctx, CFG, tag, 'acf_cuts');
        runViz(CFG.viz.skeleton,    @viz_skeleton,  D, meta, ctx, CFG, tag, 'skeleton');
        runViz(CFG.viz.levelBands,  @viz_level_bands, D, meta, ctx, CFG, tag, 'level_bands');
    end
end
end

% ------------------------------------------------------------------------
function runViz(enabled, fn, D, meta, ctx, CFG, tag, name)
% Виклик модуля візуалізації з обробкою помилок: збій одного рисунка
% логується і НЕ валить решту прогону.
if ~enabled, return; end
try
    fn(D, meta, ctx, CFG);
catch ME
    fprintf(2, '   [viz fail] %s %s: %s\n', tag, name, ME.message);
end
end
