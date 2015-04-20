function [y, fy] = svm_extractsv(Sv, Pair, y, fy),
%SVM_EXTRACTSV extract Sv from the data set

ell = length(fy);
% and update our collection of known points which is composed of Support
% vectors and this new point
strip = [];
for i=1:ell, % strip away all data point that are not support vectors
  if ~(any(any(i == Pair(:,Sv)))), strip = [strip i]; end
end
y(:,strip) = []; fy(strip) = [];
