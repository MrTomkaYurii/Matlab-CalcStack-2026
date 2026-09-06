function tp_phase_trend(CFG, sampleName, example)
% TP_PHASE_TREND  Тренд статистики (mean +- std модуля й аргументу) кожного
%   елемента f_ik проти номера фазової вибірки k=1..CFG.phase.numWindows.
%   Незалежний від основного розрахунку: читає вже збережені result.mat з
%   усіх phase_XX тек (як run_TwoPoint_CollectForHorsky), нічого не рахує
%   заново. Одна оглядова фігура 4x4 (усі 16 f_ik) на кожен алгоритм+напрям,
%   окремо для модуля й окремо для аргументу.

if isempty(example)
    sampleOut   = sampleName;
    sampleLabel = sampleName;
else
    sampleOut   = fullfile(sampleName, example);
    sampleLabel = sprintf('%s / %s', sampleName, example);
end

N = CFG.phase.numWindows;
U = tp_phase_window_bounds(CFG);

for a = 1:numel(CFG.algorithms)
    algo = CFG.algorithms{a};
    agg  = struct();   % agg.(dirName).(elem) = struct(muMod,sdMod,muArg,sdArg) [1xN]

    for k = 1:N
        phaseFolder = tp_phase_folder_name(CFG, k);
        if strcmpi(algo, 'generalized')
            for si = 1:numel(CFG.gen.steps)
                rf = fullfile(CFG.paths.saveRoot, sampleOut, phaseFolder, algo, ...
                              sprintf('step_%d', CFG.gen.steps(si)), 'result.mat');
                agg = accumulate(agg, rf, k, N);
            end
        elseif strcmpi(algo, 'polar')
            % polar: окремий result.mat у теках PERP\ , OX\ , OY\ (крок = радіус rho).
            % Обов'язково включаємо PERP — це і є ЄДИНА карта полярного алгоритму;
            % без цієї гілки тренд брав би шлях ортогонального (OX/OY зі списку
            % CFG.ortho.steps) і мовчки минав PERP.
            for dirLabel = {'PERP','OX','OY'}
                for si = 1:numel(CFG.polar.radii)
                    rf = fullfile(CFG.paths.saveRoot, sampleOut, phaseFolder, algo, ...
                                  dirLabel{1}, sprintf('step_%d', CFG.polar.radii(si)), 'result.mat');
                    agg = accumulate(agg, rf, k, N);
                end
            end
        elseif strcmpi(algo, 'XY')
            % XY: ЗВЕДЕНА карта (OX+OY) — окремий result.mat на крок (тека
            % XY\step_<d>\, змінна R), як generalized. Кроки = CFG.ortho.steps.
            for si = 1:numel(CFG.ortho.steps)
                rf = fullfile(CFG.paths.saveRoot, sampleOut, phaseFolder, 'XY', ...
                              sprintf('step_%d', CFG.ortho.steps(si)), 'result.mat');
                agg = accumulate(agg, rf, k, N);
            end
        else
            % orthogonal: окремий result.mat у КОЖНІЙ підтеці <OX|OY>\step_N\
            for dirLabel = {'OX','OY'}
                for si = 1:numel(CFG.ortho.steps)
                    rf = fullfile(CFG.paths.saveRoot, sampleOut, phaseFolder, algo, ...
                                  dirLabel{1}, sprintf('step_%d', CFG.ortho.steps(si)), 'result.mat');
                    agg = accumulate(agg, rf, k, N);
                end
            end
        end
    end

    dirNames = fieldnames(agg);
    for di = 1:numel(dirNames)
        try
            renderTrend(agg.(dirNames{di}), dirNames{di}, algo, sampleOut, sampleLabel, U, CFG);
        catch ME
            fprintf(2, '   [viz fail] phase_trend %s/%s: %s\n', algo, dirNames{di}, ME.message);
        end
    end
end
end

% ------------------------------------------------------------------------
function agg = accumulate(agg, rf, k, N)
if ~isfile(rf), return; end
S = load(rf);           % ім'я змінної різне: 'R' (generalized) чи 'Rd' (orthogonal, по підтеках)
fn = fieldnames(S); R = S.(fn{1});
for d = 1:numel(R.dirs)
    dirName = R.dirs{d};
    if ~isfield(agg, dirName), agg.(dirName) = struct(); end
    elems = fieldnames(R.data.(dirName));
    for e = 1:numel(elems)
        elem = elems{e};
        if ~isfield(agg.(dirName), elem)
            agg.(dirName).(elem) = struct('muMod',nan(1,N), 'sdMod',nan(1,N), ...
                                           'muArg',nan(1,N), 'sdArg',nan(1,N));
        end
        D = R.data.(dirName).(elem);
        vMod = D.mod(isfinite(D.mod));
        vArg = D.arg(isfinite(D.arg));
        [muM,sdM] = tp_moments(vMod, false);
        [muA,sdA] = tp_moments(vArg, true);
        agg.(dirName).(elem).muMod(k) = muM;
        agg.(dirName).(elem).sdMod(k) = sdM;
        agg.(dirName).(elem).muArg(k) = muA;
        agg.(dirName).(elem).sdArg(k) = sdA;
    end
end
end

% ------------------------------------------------------------------------
function renderTrend(dirAgg, dirName, algo, sampleOut, sampleLabel, U, CFG)
S = viz_style();
xVals = U / pi;   % фізична вісь: верхня межа вікна U_k, у частках pi

sets = { {'muMod','sdMod','Module  |f_{ik}|  vs phase window','modules','|f_{ik}|'}, ...
         {'muArg','sdArg','Argument  Arg(f_{ik})  vs phase window','arguments','Arg(f_{ik})  (rad)'} };

for si = 1:numel(sets)
    muF = sets{si}{1}; sdF = sets{si}{2}; ttl = sets{si}{3}; tag = sets{si}{4}; ylab = sets{si}{5};

    fig = figure('Color','w','Visible','off','Position',[40 40 1500 1050]);
    S.light(fig);
    for i = 1:4
        for kk = 1:4
            elem = sprintf('f%d%d', i, kk);
            axp = subplot(4,4,(i-1)*4 + kk);
            if ~isfield(dirAgg, elem), axis(axp,'off'); continue; end
            mu = dirAgg.(elem).(muF); sd = dirAgg.(elem).(sdF);
            errorbar(axp, xVals, mu, sd, 'o-', 'Color',[0.20 0.40 0.80], ...
                     'MarkerFaceColor',[0.20 0.40 0.80], 'LineWidth',1.2, 'MarkerSize',4, 'CapSize',3);
            set(axp, 'XDir','reverse');   % k=1 (широке [0,2pi]) ліворуч -> k=N (вузьке) праворуч
            xlim(axp, [min(xVals)-0.05, max(xVals)+0.05]);
            xlabel(axp, 'U_k / \pi  (window upper bound)', 'FontSize',8);
            ylabel(axp, ylab, 'FontSize',8);
            title(axp, sprintf('f_{%d%d}', i, kk), 'FontSize',10,'FontWeight','bold','Interpreter','tex');
            S.apply(axp);
        end
    end
    sgtitle(sprintf('%s  \\cdot  %s  \\cdot  %s  \\cdot  %s', ...
            strrep(sampleLabel,'\','/'), algo, strrep(dirName,'_','\_'), ttl), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);

    outDir = fullfile(CFG.paths.saveRoot, sampleOut, 'phase_trend', algo, dirName);
    if ~exist(outDir,'dir'); mkdir(outDir); end
    outFile = fullfile(outDir, sprintf('trend_%s.%s', tag, CFG.out.format));
    try
        exportgraphics(fig, outFile, 'Resolution', CFG.out.dpi);
    catch
        print(fig, outFile, ['-d' CFG.out.format], sprintf('-r%d', CFG.out.dpi));
    end
    if CFG.out.closeAfter && ishandle(fig), close(fig); end
end
end
