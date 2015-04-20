function I = svm_find(Sv, Pair, ell),
%SVM_FIND finf unique Sv from the data pair set

% and update our collection of known points which is composed of Support
% vectors and this new point
I = ones(1,ell);
for i=1:ell, % strip away all data point that are not support vectors
  if ~(any(any(i == Pair(:,Sv)))), I(i) = 0; end
end
I = find(I == 1);
