function kernel2file(y,K,fname),
%KERNEL2FILE Write kernel to file for precomputed kernel LIBSVM

n = length(y)
if ~all(size(K) == [n n]),
  error('size of K must be the same as length of y');
end

fid = fopen(fname,'w');
indx = 1:length(y);
for i = 1:length(y),
  string1 = [num2str(y(i)) ' '];
  values(1:2:2*n-1) = indx;
  values(2:2:2*n) = K(i,:);
  string2 = sprintf('%.6f ', values);
  fprintf(fid,'%s\n', [string1 string2]);
end
fclose(fid);
  
