function [model,trainaccuracy] = svm_libsvm(X1,X2,y,C),
%SVM_LIBSVM Support vector machine (1C-norm) for pairs
% uses function pairkernel mex-file to generate the kernel
% example usage: [alpha, SV, accuracy] = svm_pair(X1, X2, y, C, alpha);
% Default C = 1; Default alpha = zeros(ell,1);

if (nargin < 3), error('usage: [alpha, SV, accuracy] = svm_pair(X1,X2,y,C,alpha)'); end
if (nargin < 4), C = 1; end % default value for C

ell = length(y); Sv = []; trainaccuracy = 0;

% Set up the QP problem:
K = pairkernel(X1, X2);
y = y';
% fire up libsvm
tic
model = svmtrain(y, [(1:length(y))' K], ['-s 0 -t 4 -c ' num2str(C)])
toc
yhat = svmpredict(y, [(1:length(y))' K], model)

% compute the training accuract in %-age
trainaccuracy = sum(sign(yhat) == y)/ell*100;

