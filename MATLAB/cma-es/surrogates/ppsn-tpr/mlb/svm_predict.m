function yest = svm_predict(x, X1, X2, alpha, y12),
%SVM_PREDICT Predict ordinal value using the pairs and alpha

K1 = pairkernel(X1,x,0);
K2 = pairkernel(X2,x,0);
yest = (alpha.*y12)*(K1-K2); % + b;

