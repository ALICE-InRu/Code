function [alpha, Sv, trainaccuracy, K] = svm_pair(X1,X2,y,Gamma,C,alpha),
%SVM_PAIR Support vector machine (1C-norm) for pairs
% uses function pairkernel mex-file to generate the kernel
% example usage: [alpha, SV, accuracy] = svm_pair(X1, X2, y, gamma, C, alpha);
% Default C = 1; Default alpha = zeros(ell,1);

if (nargin < 3), error('usage: [alpha, SV, accuracy] = svm_pair(X1,X2,y,gamma,C,alpha)'); end
ell = length(y);
if (nargin < 4), C = 1; end % default value for C
if (nargin < 5), alpha = zeros(ell,1); end % default value for alpha

% Set up the LIBSVM problem using precomputed kernel:
% addpath /home/hei2/Work/toolbox/libsvm-mat-2.91-1
K = pairkernel(X1, X2, Gamma); % 2-norm
y

% To use precomputed kernel, you must include sample serial number as
% the first column of the training and testing data (assume your kernel
% matrix is K, # of instances is n):
K1 = [(1:length(X1))', K]; % include sample serial number as first column
model_precomputed = svm_train(y', K1, ['-t 4 -c ' num2str(C)]);

% % model_precomputed = 
% % 
% %     Parameters: [5x1 double]
% %       nr_class: 2
% %        totalSV: 73
% %            rho: 3.9581e-04
% %          Label: [2x1 double]
% %          ProbA: []
% %          ProbB: []
% %            nSV: [2x1 double]
% %        sv_coef: [73x1 double]
% %            SVs: [73x1 double]
alpha=zeros(length(X1),1);
tmp=1:ell;
Sv=tmp(model_precomputed.SVs);
alpha(Sv)=y(1)*(y(Sv)'.*model_precomputed.sv_coef);
% [predict_label_P, accuracy_P, dec_values_P] = svmpredict(test_label, [(1:120)', test_data*train_data'], model_precomputed);

% % K = pairkernel(X1, X2); % 1-norm
% f = -ones(ell,1);
% A = zeros(1,ell); c = 0;
% Aeq = y; ceq = 0;
% LB = zeros(ell,1);
% UB = ones(ell,1)/eps; % very lage number
% H = (y' * y) .* (K + eye(ell)/C);
% Sv = []; trainaccuracy = 0;
% % Use Smola's QP solver:
% 
% if eig(H)>0,  
%   alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,0,0);
% else disp('!! Error matrix not semi positive definite'); 
% end
% % [alpha, feval, exitflag] = quadprog(H,f,A,c,Aeq,ceq,LB,UB,alpha);exitflag
% % determine the support vectors:
% % tol = max([eps max(abs(alpha))/1000]);
% % Sv = find(alpha > tol & alpha < (C-tol)) % 1-norm
% Sv = find(alpha > eps);
fest = (alpha(Sv)'.*y(Sv))*K(Sv,:);
% %%fmargin = max(abs(fest))
% % compute the training accuract in %-age
trainaccuracy = sum(sign(fest) == y)/ell*100
% %{
% if (isempty(Sv)), % A Debug crash !!!
%   X1, X2, y, alpha', tol, Sv, 
%   fest = (alpha(Sv)'.*y(Sv))*K(Sv,:);
%   trainaccuracy = sum(sign(fest) == y)/ell*100
%   pause;
% end
% %}

alpha = alpha'; % return the transpose!