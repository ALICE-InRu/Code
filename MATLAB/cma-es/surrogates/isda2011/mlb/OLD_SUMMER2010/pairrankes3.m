% Written by tpr@hi.is (ordinal regression)
% ordinal regression evolution strategy (ORES)

clear all, close all, format compact
%rand('state',0); randn('state',0); % set seed to initial state!!!

% parameters for the simulation
R = 100;
maxell = 30;
ell = 2;
lambda = 30;
n = 30; % dimensions for the problem
sigma = 1; % standard deviation of the search distribution
xp = [R;zeros(n-1,1)]; % initial starting point for progress rate simulator (the current parent point)
x = xp*ones(1,lambda) + randn(n,lambda);

% the true know values are kept in y!
yp = [R;zeros(n-1,1)]; % point where model samples are created
y = yp*ones(1,ell) + randn(n, ell);
fy = func(y);

% this sorting is optional (for better visual inspection)
%[fy,I] = sort(fy); y = y(:,I); fy = fy;

kentautest = 0; % used for stopping the model estimate procedure!
festxold = [];
counter = 0;
while (kentautest(counter+1) < 0.99999),
  counter = counter + 1;
% create new data pair set:
  [y1, y2, fy12, Pair] = createdatapair(y, fy, min([maxell ell]));
  m = length(fy12)

% Solve using the SVM and predict the output
% default initial values for solver;
  alpha = zeros(m,1); C = 1;
% Ordinal support vector regression
  [alpha, Sv, trainaccuracy, K] = svm_pair(y1, y2, fy12, C, alpha);
% prediction the output
  fyest = svm_predict(y, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv))
% use Kendall's tau to evaluate diffence in ranking
  ykentau(counter) = kendalltau(fyest,func(y));

% now do a prediction for unknown population of sample points
  fxest = svm_predict(x, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));

% check how the ranking compared with previous attempt:
  if (counter > 1), xokentau(counter) = kendalltau(fxest, fxestold); end
% extract the best point:
  [fbxest,inx] = min(fxest);
  xbest = x(:,inx);

% evaluate some statistics for this estimate against true values;  
%  tiedrank(func(x))
  fxtrue = func(x);
  xkentau(counter) = kendalltau(fxest, fxtrue);
  [dummy, inxbest] = min(fxtrue);
  ptrue(counter) = (inxbest == inx)

% remove this one from the population
  x(:,inx) = []; fxest(inx) = []; fxestold = fxest;
  
% and update our collection of known points which is composed of Support
% vectors and this new point
  strip = [];
  for i=1:ell, % strip away all data point that are not support vectors
    if ~(any(any(i == Pair(:,Sv)))), strip = [strip i]; end
  end
  y(:,strip) = []; fy(strip) = [];
  ell = length(fy);
% add this new point to the data set:
  ell = ell + 1, y(:,ell) = xbest; fy(ell) = func(xbest);

% how does our old system rank this new data point?
  fyest = svm_predict(y, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
  kentautest(counter+1) = kendalltau(fyest, fy)

% if the data point in x are already too small and we are not making progress we should bail out with an error  
  if (size(x,2) == 1),
    warning('you should try a different kernel or increase C!');
    break;
  end
  
end % the old model is unable to cope with this new point and so we should redo the model
