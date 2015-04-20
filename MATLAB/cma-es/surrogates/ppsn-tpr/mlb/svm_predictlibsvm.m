function yest = svm_predictlibsvm(x, X1, X2, model, y12),
%SVM_PREDICT Predict ordinal value using the pairs and alpha

K1 = pairkernel(X1,x,0);
K2 = pairkernel(X2,x,0);
size(y12), size(K1-K2)

size(x,2)

[a,b,yest] = svmpredict(ones(size(x,2),1), [(1:size(x,2))' (K1-K2)'],model);
yest = -yest';

