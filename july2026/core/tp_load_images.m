function IMG = tp_load_images(CFG, sampleName, exampleName)
% TP_LOAD_IMAGES  Повертає вкладену структуру поляризаційних зображень зразка.
%   Диспетчеризує за CFG.source:
%       'synthetic' -> tp_gen_synthetic (sampleName ігнорується)
%       'real'      -> читає шість BMP-файлів на освітлення й обрізає N x N
%
%   exampleName (необов'язково) — конкретна підтека всередині зразка
%       (напр. 'zrazok_1'). Якщо не задано — береться CFG.paths.example
%       (запасний варіант для одиничних тестового/симуляційного проходів).
%
%   IMG.(inPol).(analyzer) : N x N double у [0,1]

if strcmpi(CFG.source, 'synthetic')
    IMG = tp_sim_speckle_BT(CFG);   % фізична симуляція двопроменезаломної БТ
    return;
end

if nargin < 3 || isempty(exampleName)
    exampleName = CFG.paths.example;
end

% -------- реальне вимірювання ----------------------------------------
N  = CFG.crop.size;
y0 = CFG.crop.y0;  x0 = CFG.crop.x0;
readDir = fullfile(CFG.paths.readRoot, sampleName, exampleName);

% освітлення -> префікс файлу, і шість суфіксів аналізатора
inPols   = {'in0','in45','in90','inRC'};
prefixes = {'0'  ,'45'  ,'90'  ,'prav'};
suffix   = struct('I0','0','I45','45','I90','90','I135','135','Iliv','liv','Iprav','prav');
anFields = fieldnames(suffix);

IMG = struct();
for p = 1:numel(inPols)
    S = struct();
    for a = 1:numel(anFields)
        fname = fullfile(readDir, sprintf('%s-%s.bmp', prefixes{p}, suffix.(anFields{a})));
        if ~isfile(fname)
            error('tp_load_images:missing', 'Зображення не знайдено: %s', fname);
        end
        img = imread(fname);
        if size(img,3) == 3, img = rgb2gray(img); end
        img = double(img) / 255;
        tp_assert(size(img,1) >= y0+N-1 && size(img,2) >= x0+N-1, ...
            'Зображення %s (%dx%d) замале для crop %d від (%d,%d)', ...
            fname, size(img,1), size(img,2), N, x0, y0);
        S.(anFields{a}) = img(y0:y0+N-1, x0:x0+N-1);
    end
    IMG.(inPols{p}) = S;
end
end
