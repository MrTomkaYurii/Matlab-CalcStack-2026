function tz_write_csv(f, rows)
% TZ_WRITE_CSV  Рядки стат-моментів (cell, як з tz_stats) -> CSV у UTF-8 з шапкою.
H = {'block','sub','fig','col','sample','example','algo','window','elem','quantity', ...
     'N','Z1','Z2','Z3','Z4','extra'};
if isempty(rows); rows = cell(0, numel(H)); end
d = fileparts(f);  if ~isempty(d) && ~exist(d, 'dir'); mkdir(d); end
writecell([H; rows], f, 'Encoding','UTF-8');
end
