clear all, close all
addpath ..\
distr='j.rnd'; dim='10x10'; 
problems  = getproblem(sprintf('../../rawData/%s.%s.train.txt',distr,dim));
load(sprintf('../trainingData/%s.%s.train.OPT.tpr.mat',distr,dim),'DAT')
%%
Xdir = []; Ydir = []; Xopt=[]; Xsub=[];
fjoldi = zeros(100,1);
for t = 1:length(DAT), t,%length(DAT)
  data_opt = [];
  data_sub = [];
  data_idx = [];
  dat = DAT(t).dat;
  optimal = min(dat(:,2));
  [n,m] = size(problems(t).p);
  for i = 1:n*m
    data = dat((i == dat(:,1)),:);
    %[~,rnk] = sort(data);
    %normdata = data./(ones(size(data,1),1)*sum(data));
    optidx = find(data(:,2) == optimal);
    subidx = find(data(:,2) ~= optimal);
    for j = 1:length(optidx)
      for k = 1:length(subidx)
        data_opt = [data_opt;data(optidx(j),4:17)];
        data_sub = [data_sub;data(subidx(k),4:17)];
        data_idx = [data_idx;i];
        fjoldi(i) = fjoldi(i)+1;
      end
    end
  end
  Xopt = [Xopt;data_opt];
  Xsub = [Xsub;data_sub];
  Xdir = [Xdir;data_opt;data_sub];
  Ydir = [Ydir;ones(length(data_opt),1);zeros(length(data_sub),1)];
end
%%
y = ones(length(Xopt),1);
diff_data = [Xopt - Xsub];
X = []; Y = [];
for i=1:n*m,i
  idx = (data_idx == i);
  I = randperm(length(idx)); I = idx(I(1:min(length(idx),100000000000000000)));
  X = [X;diff_data(I,:);-diff_data(I,:)];
  Y = [Y;y(I);-y(I)];
end
%%
%X = [diff_data;-diff_data];
%Y = [y;-y];
valid_error = train(Y,sparse(X),'-s 0 -v 10 -q')
model = train(Y,sparse(X),'-s 0 -q')

% or direct classification
model = train(Ydir,sparse(Xdir),'-s 0 -q')

