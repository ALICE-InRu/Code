function mat2libsvm(X, y, fname, qid) 
%MAT2LIGHT write matlab variables X and y to SVM_LIGHT training data file
%
% usage: mat2light(X, y, fname)

% Copyleft 2006 Thomas Philip Runarsson (20/3)

if (nargin < 4), qid = []; end

[ell n] = size(X);
if (ell ~= length(y(:)))
  error('fault the length of y must be the same as the number of rows in X');
end
fid = fopen(fname,'wt');
if fid == -1,
  error(sprintf('fault: could not write to file %s',fname));
end
disp(sprintf('writing file %s, please wait ...', fname));
for i = 1:ell,
  if isempty(qid),
    string = num2str(y(i)) ; % sprintf('%f', double(y(i)));
  else
    string = [num2str(y(i)) ' qid:' num2str(qid(i))] ; % sprintf('%f', double(y(i)));
  end
  for j = 1:n,
    if X(i,j)~=0,
      string = [string ' ' num2str(j) ':' num2str(double(X(i,j)))];
    end
  end
  fprintf(fid,'%s\n',string);
end
disp('done writing file!');
fclose(fid);
