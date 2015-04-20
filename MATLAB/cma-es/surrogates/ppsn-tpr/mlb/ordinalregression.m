function [fx, y, fy, funceval] = ordinalregression(x, y, fy, fx, repeat),
% ORDINALREGRESSION: Ordinal regression ranking
% Usage: fx = ordrank(x, y, fy, fx, repeat);

% keep original data
xorg = x; fxorg = fx;
yorg = y; fyorg = fy;
% work out scaling factor
[scalefac, offset] = svm_scale([x y]);
% scale the data
scx = svm_scale(x, scalefac, offset);
scy = svm_scale(y, scalefac, offset);
% keep original scaled data
scxorg = scx; scyorg = scy;
% set function evaluation counter to zero
funceval = 0;
% loop through until kendall tau is 1
indid = 1:length(fx); indtrack = [];
while (1), 
% create new data pair set:
  [y1, y2, fy12, Pair] = createdatapair(scy, fy); m = length(fy12);
% default initial values for solver;
  alpha = zeros(m,1); C = 1000000;
% ordinal support vector regression
  [alpha, Sv, trainaccuracy, K] = svm_pair(y1, y2, fy12, C, alpha);
% echo to used the training accuracy if not zero!
  if (trainaccuracy < 100), trainaccuracy,end
% bail out now if this was the last training example:
  if isempty(scx),trainaccuracy; break; end
% now do a prediction for unknown population of sample points
  fxest = svm_predict(scx, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
% find the best estimated point and add it to the training set
  [dummy, ib] = min(fxest);
% evaluate its true fitness and store in set
  fy = [fy fx(ib)]; y = [y x(:,ib)]; scy = [scy scx(:,ib)];
  funceval = funceval + 1;
% keep a track of those that have been added to the training set:
  indtrack = [indtrack indid(ib)];
% delete the best estimated from the set!
  x(:,ib) = []; fx(ib) = [];  scx(:,ib) = []; indid(ib) = [];
% check how we would rank the new training set and compare with the true value
  fyest = svm_predict(scy, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
  ktauy = kendalltau(fyest, fy);
% if the new point is ranked correctly using this new model, then bail out!  
%  if (0.999 < ktauy) & (funceval >= repeat), break; end  
  if (0.999 < ktauy), break; end
  
  % strip out all non-Svs (data reduction technique)
%%  I = svm_find(Sv, Pair, length(fy)-1);
%%  if (length(I) < length(fy)), y = y(:,I); fy = fy(:,I); scy = scy(:,I); end
% delete very old data points from data set
%% while (length(fy) > 30),  y(:,1) = []; fy(1) = []; scy(:,1) = []; end
end
% return the predicted function values for original data!
fx = svm_predict(scxorg, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
