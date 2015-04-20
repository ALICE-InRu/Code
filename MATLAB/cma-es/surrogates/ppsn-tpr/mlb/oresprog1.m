function [fybest, ybest, fcneval, pval, ptrue] = oresprog(xp, eta, lambda, ell, maxell, maxfcneval),
% ORESPROG: Ordinal regression evolution strategy
% Usage: [fybest, ybest, fcneval, ptrue] = oresprog(xp, sigma, lambda, ell, maxell, maxfcneval),

% Written by tpr@hi.is (ordinal regression)
% ordinal regression evolution strategy (ORES)

% parameters for the simulation
n = length(xp); % dimensions for the problem
x = xp*ones(1,lambda) + eta*randn(n,lambda);

% the true know values are kept in y!
% create two true true function evaluations:
I = randperm(lambda); 
y = x(:,I(1:ell)); % point where model samples are created
fy = func(y); fcneval = ell;
[fybest, i] = min(fy); ybest = y(:,i); % record the best solution
% remove this from our data set
x(:,I(1:ell)) = [];

% create initial model using this data pair set:
[y1, y2, fy12, Pair] = createdatapair(y, fy, min([maxell ell]));
m = length(fy12);
% Solve using the SVM and predict the output
% default initial values for solver;
alpha = zeros(m,1); C = 1;
% Ordinal support vector regression
[alpha, Sv, trainaccuracy, K] = svm_pair(y1, y2, fy12, C, alpha);
% now do a prediction for unknown population of sample points
fxest = svm_predict(x, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
% extract the best point:
[fbxest,inx] = min(fxest);
xbest = x(:,inx);

kentautest = 0; % used for stopping the model estimate procedure!
dualtest = 0;
counter = 1;
festxold = fxest;

%while ((kentautest(counter+1) < 0.99999) & (counter <(maxfcneval-fcneval))), counter = counter + 1;
while ((dualtest < 0.9) & (counter <(maxfcneval-fcneval))), counter = counter + 1;
%for counter = 1:(maxfcneval-fcneval), % additional function evaluations
% create new data pair set:
  [y1, y2, fy12, Pair] = createdatapair(y, fy, min([maxell ell]));
  m = length(fy12);

% Solve using the SVM and predict the output
% default initial values for solver;
  alpha = zeros(m,1); C = 1;
% Ordinal support vector regression
  [alpha, Sv, trainaccuracy, K] = svm_pair(y1, y2, fy12, C, alpha);
% prediction the output
  fyest = svm_predict(y, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
% use Kendall's tau to evaluate diffence in ranking
  ykentau(counter) = kendalltau(fyest,func(y));

% now do a prediction for unknown population of sample points
  fxest = svm_predict(x, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));

% extract the best point:
  [fbxest,inx] = min(fxest);
  xbest = x(:,inx);

% evaluate some statistics for this estimate against true values;  
%  tiedrank(func(x))
%%%  fxtrue = func(x);
%%%  xkentau(counter) = kendalltau(fxest, fxtrue);
%%%  [dummy, inxbest] = min(fxtrue);
%%%  ptrue(counter) = (inxbest == inx);

% and update our collection of known points which is composed of Support
% vectors and this new point
  strip = [];
  for i=1:ell, % strip away all data point that are not support vectors
    if ~(any(any(i == Pair(:,Sv)))), strip = [strip i]; end
  end
  y(:,strip) = []; fy(strip) = [];
  ell = length(fy);
% add this new point to the data set:
  ell = ell + 1; y(:,ell) = xbest; fy(ell) = func(xbest);

% record the best found solution 
  if (fybest > fy(ell)), fybest = fy(ell); ybest = xbest; end
 
% how does our old system rank this new data point?
  fyest = svm_predict(y, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
  kentautest(counter+1) = kendalltau(fyest, fy);

% check how the ranking compared with previous attempt:

  if (counter > 1), xokentau(counter) = kendalltau(fxest, fxestold); end
 
  
% the dual test
  if (counter > 1), dualtest = (kentautest(counter+1) + xokentau(counter)) / 2; end

% parent test:


% remove the newly evaluate out of the population
  x(:,inx) = []; fxest(inx) = []; fxestold = fxest;


  
% if the data point in x are already too small and we are not making progress we should bail out with an error  
  if (size(x,2) == 1),
    warning('you should try a different kernel or increase C!');
    break;
  end
  
end % the old model is unable to cope with this new point and so we should redo the model

% here are the results I would like to return from the simulation
fcneval = fcneval + counter;

%%%if (fybest == fbestvalueknown), pval = 1; else, pval = 0; end