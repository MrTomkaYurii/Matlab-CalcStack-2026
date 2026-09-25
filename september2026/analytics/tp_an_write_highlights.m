function tp_an_write_highlights(allS, catalog, outFile)
% TP_ANALYTICS_WRITE_HIGHLIGHTS  Плаский CSV-список лише того, що отримало
%   позначку (тренд/розрізняє/обидва) — людською мовою, з конкретними
%   числами (не абстрактний "score"), щоб можна було одразу прочитати
%   висновок без відкривання картинок.

labelOf = containers.Map();
groups = {'statistics','correlation','fractal'};
for g = 1:numel(groups)
    entries = catalog.(groups{g});
    for e = 1:numel(entries)
        labelOf(entries{e}{1}) = entries{e}{2};
    end
end

rows = struct('metric',{},'metric_label',{},'element',{},'badge',{},'details',{});
metricNames = fieldnames(allS);
for m = 1:numel(metricNames)
    metricName = metricNames{m};
    S = allS.(metricName);
    if isempty(S.elements), continue; end
    for ei = 1:numel(S.elements)
        elem = S.elements{ei};
        badge = S.badge.(elem);
        if strcmp(badge, 'none'), continue; end

        series = S.series.(elem);
        r2s    = S.trendR2.(elem);
        slopes = S.trendSlope.(elem);
        sampleMeans = mean(series, 2, 'omitnan');
        [maxV, maxI] = max(sampleMeans);
        [minV, minI] = min(sampleMeans);

        parts = {};
        if any(strcmp(badge, {'trend','both'}))
            dirTxt = 'зростає';
            if median(slopes,'omitnan') > 0, dirTxt = 'спадає (зі звуженням вікна)'; else, dirTxt = 'зростає (зі звуженням вікна)'; end
            parts{end+1} = sprintf('R^2(медіана)=%.2f, %s', median(r2s,'omitnan'), dirTxt); %#ok<AGROW>
        end
        if any(strcmp(badge, {'discrim','both'}))
            parts{end+1} = sprintf('%s вище за %s на %.3g', char(S.samples(maxI)), char(S.samples(minI)), maxV-minV); %#ok<AGROW>
        end

        r = struct();
        r.metric = metricName;
        if isKey(labelOf, metricName), r.metric_label = labelOf(metricName); else, r.metric_label = metricName; end
        r.element = elem;
        r.badge = badge;
        r.details = strjoin(parts, '; ');
        rows(end+1) = r; %#ok<AGROW>
    end
end

fid = fopen(outFile, 'w', 'n', 'UTF-8');
fprintf(fid, 'metric,metric_label,element,badge,details\n');
for i = 1:numel(rows)
    fprintf(fid, '%s,"%s",%s,%s,"%s"\n', rows(i).metric, rows(i).metric_label, ...
            rows(i).element, rows(i).badge, rows(i).details);
end
fclose(fid);
fprintf('  [highlights] %d позначених (елемент x метрика) з %d\n', numel(rows), numel(metricNames)*5);
end
