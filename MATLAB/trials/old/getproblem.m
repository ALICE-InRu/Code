function problems = getproblem(fname)
%GETPROBLEMS
% usage: problems = getproblem(fname)

fid = fopen(fname);
if (-1==fid)
  error(sprintf('could not find file %s',fname));
end
while 1
  tline = fgetl(fid);
  if (1 == strncmp('instance problem.',tline,17))
    k = str2double(tline(18:end))+1;
    fgetl(fid); % get rid of the pluses
    [nm] = eval(['[' fgetl(fid) ']']);
    data = zeros(nm(1),2*nm(2));
    for i=1:nm(1)
      data(i,:) = eval(['[' fgetl(fid) ']']);
    end
    problems(k).p = data(:,2:2:end);
    problems(k).sigma = data(:,1:2:end)+1;
  end
  if ~ischar(tline), break, end
end
fclose(fid);
