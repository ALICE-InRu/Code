function [alpha, b, K, R] = perceptron_dual_kernel_ranking(X, y, d)
%PERCEPTRON_DUAL_KERNEL_RANKING perceptron algorithm in dual form + kernel
% usage: [alpha, b, K, R] = perceptron_dual_kernel_ranking(X, y, d)

% Copyleft 2006 Thomas Philip Runarsson

% length of the input vector
  n = size(X,2);
% the number of training samples
  ell = size(X,1);
% initial bias, zeros (assume the size of Y is max(y))
  b = zeros(max(y),1); b(end) = inf;
% convergence flag
  flag = 1;
% compute the Kernel matrix (external function kernel.m)
  K = kernel(X,X,d);
% the parameter R
  R = max(sqrt(diag(K)));
% the dual variables alpha 
  alpha = zeros(ell,1);
% start repeat (while) loop
  while (1 == flag),
%  for inter = 1:10000,
    flag = 0;
    for i = randperm(ell),
      yr = min(find(((alpha)'*K(:,i)  < b)));
      if (yr < y(i)),
        alpha(i) = alpha(i) + (y(i) - yr);
        b(1:y(i)-1) = b(1:y(i)-1) - 1;
        flag = 1;
      elseif (yr > y(i)),
        alpha(i) = alpha(i) - (yr - y(i));
        b(y(i):yr-1) = b(y(i):yr-1) + 1;
        flag = 1;
      end
    end
  end
  