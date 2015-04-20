function [fx, y, fy, funceval] = ordinalregression(x, y, fy, strfitnessfct, repeat, param),
% ORDINALREGRESSION: Ordinal regression ranking
% Usage: fx = ordinalregression(x, y, fy, strfitnessfct, param);

% x eru einsog punktar fyrir næstu kynslóð 
% y eru punktar nú þegar í training data -> fy er þeirra sanna 

global mu 

% keep original data
xorg = x; yorg = y; fyorg = fy;
% work out scaling factor
[scalefac, offset] = svm_scale([x y]);
% scale the data
scx = svm_scale(x, scalefac, offset);
scy = svm_scale(y, scalefac, offset);
% keep original scaled data
scxorg = scx; scyorg = scy;

% set function evaluation counter to zero
funceval = 0;

% Indices of x(:,i) added to the training set 
indtrack = []; indid = 1:length(x);

% loop through until kendall tau is 1
while (1), 
% create new data pair set:
  [y1, y2, fy12, Pair] = createdatapair(scy, fy); m = length(fy12);
% default initial values for solver;
  alpha = zeros(m,1); C = 1000000;
% ordinal support vector regression
  [alpha, Sv, trainaccuracy, K] = svm_pair(y1, y2, fy12, C, alpha);
  
  if funceval >= repeat, break; end % Bail out to final prediction!

% echo to used the training accuracy if not zero!
%  if (trainaccuracy < 100), trainaccuracy, end

if param.emptyX
  % bail out now if this was the last training example:
  if isempty(scx),trainaccuracy; break; end
end

% now do a prediction for unknown population of sample points
  fxest = svm_predict(scx, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));

  
  
% ---- CHOICE OF POINTS TO ADD TO TRAINING DATA --------------
if param.emptyX
  % find the best estimated point and add it to the training set
  [dummy, ib] = min(fxest);
else
  % Pick x corresponding to the best est. point not yet added to the training set
  [dummy, indices]=sort(fxest,'ascend');
  for i=1:length(indices), 
    if ~ismember(indices(i),indtrack)
      ib = indices(i); break
    end
  end
  % If the mu best indices have already been added to the training data, then bail out!  
  if isempty(setdiff(indices(1:mu),indtrack)), break; end
end

% evaluate its true fitness and store in set
  fy = [fy feval(strfitnessfct, x(:,ib))]; y = [y x(:,ib)]; scy = [scy scx(:,ib)];
  funceval = funceval + 1;
  
% keep track of those who have been added to the training set:
  indtrack = [indtrack indid(ib)];

if param.emptyX
  % delete the best estimated from the set!
  x(:,ib) = []; scx(:,ib) = []; indid(ib) = [];
end

% check how we would rank the new training set and compare with the true value
  fyest = svm_predict(scy, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));
  ktauy = kendalltau(fyest, fy);
  
% if the new point is ranked correctly using this new model, then bail out!  
  if (0.999 < ktauy), break; end  

% !! MÁ LAGA HÉR !!
% strip out all non-Svs (data reduction technique)
%%  I = svm_find(Sv, Pair, length(fy)-1);
%%  if (length(I) < length(fy)), y = y(:,I); fy = fy(:,I); scy = scy(:,I); end
end

% return the predicted function values for original data!
fx = svm_predict(scxorg, y1(:,Sv), y2(:,Sv), alpha(Sv), fy12(Sv));