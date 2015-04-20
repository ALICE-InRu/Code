clear all, close all
distr='j.rnd';
dim='10x10';

problems  = getproblem(['../rawData/' distr '.' dim '.train.txt']);
load(['trainingData/' distr '.' dim '.train_data.mat'], 'DAT')
Ntrain = length(DAT); 

Xdir = []; Ydir = [];
for t = 1:Ntrain, 
  data_opt = [];
  data_sub = [];
  dat = DAT(t).dat;
  optimal = min(dat(:,2));
  [n m] = size(problems(t).p);
  for i = 1:n*m
    data = dat((i == dat(:,1)),:);
    %[~,rnk] = sort(data);
    %normdata = data./(ones(size(data,1),1)*sum(data));
    optidx = find(data(:,2) == optimal);
    subidx = find(data(:,2) ~= optimal);
    for j = 1:length(optidx)
      for k = 1:length(subidx)
        data_opt = [data_opt;data(optidx(j),4:end-3)];
        data_sub = [data_sub;data(subidx(k),4:end-3)];
      end
    end
  end
  Xdir = [Xdir;data_opt;data_sub];
  Ydir = [Ydir;ones(length(data_opt),1);zeros(length(data_sub),1)];
end
return
% clearly a need to scale the data for RBF kernel:
% maxX = max(Xdir);
% minX = min(Xdir);
% widthX = maxX-minX;
% Xdir = Xdir - ones(length(Xdir),1)*minX;
% Xdir = Xdir./(ones(length(Xdir),1)*widthX);
% Xdir = 2*Xdir - 1;

% now try to tune the model ...
gamma = [0.01 0.1 0.5 1];
C = [1000 10000 100000];
I = 1:length(Ydir);
nn = ceil(length(I)/2);
I1 = I(1:nn);
I2 = I((nn+1):end);
for i = 1:length(gamma)
  for j = 1:length(C) [i j]
    mmm(i,j).model = svmtrain(Ydir(I1),Xdir(I1,:),sprintf('-s 0 -h 0 -g %f -c %f',gamma(i),C(j)));
    yhat = svmpredict(Ydir(I2),Xdir(I2,:),mmm(i,j).model);
    V(i,j) = sum(yhat==Ydir(I2))/length(yhat)*100;
  end
end
return

y = ones(length(data_opt),1);
diff_data = [data_opt - data_sub];
X = [diff_data;-diff_data];
Y = [y;-y];
valid_error = train(Y,sparse(X),'-s 0 -v 10 -q')
model = train(Y,sparse(X),'-s 0 -q')

% compute true decision error on training data:
load rbfmodel
%Classify = []; rho = [];
for t = 1:Ntrain, t, 
  dat = DAT(t).dat;
  optimal = min(dat(:,2));
  for i = 1:n*m
    data = dat((i==dat(:,1)),:);
    v = data(:,4:end-3)*model_all.w';
    %v = svmpredict(ones(size(data,1),1),data(:,4:end-3),model,'-q');
    if isempty(v)
      Classify(t,i) = 1;
      rho(t,i) = 0;
    else
      [~,idx] = max(v);
      rho(t,i) = (data(idx,2)-optimal)/optimal;
      if (data(idx,2) == optimal)
        Classify(t,i) = 1;
      else
        Classify(t,i) = 0;
        [~,J]=sort(v);
        %        data(J,2)'
      end
    end
  end
end