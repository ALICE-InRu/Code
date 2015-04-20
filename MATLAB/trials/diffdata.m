clear all,% close all

%load frnd_8x8_train_data DAT
%n = 8, m=8
load jrndn_10x10_train_data_new DAT
n = 10, m = 10;
% [n,m] = size(problems(1).p);

data_opt = [];
data_sub = [];
stage = [];
for IDNUM = 1:100, % length(DAT),IDNUM,%length(DAT), IDNUM
  dat = DAT(IDNUM).dat;
  optimal = min(dat(:,2));
  for i=1:n*m, %(m*n-15):n*m
    data = dat((i==dat(:,1)),:);
    optidx = find(data(:,2) == optimal);
    subidx = find(data(:,2) ~= optimal);
    for j=1:length(optidx)
      for k=1:length(subidx)
        data_opt = [data_opt;data(optidx(j),4:end-5)];
        data_sub = [data_sub;data(subidx(k),4:end-5)];
      end
    end
    stage = [stage;i*ones(length(optidx)*length(subidx),1)];
  end
end
y = ones(length(data_opt),1);
diff_data = [data_opt - data_sub];
X = [diff_data;-diff_data];
Y = [y;-y];
%stage = [stage;stage];
xvalid_all = train(Y,sparse(X),'-s 0 -v 10 -q')
model_all = train(Y,sparse(X),'-s 0 -q');
xvalid_same = train(Y(X(:,1)==0),sparse(X(X(:,1)==0,2:end)),'-s 0 -v 10 -q')
model_same = train(Y(X(:,1)==0),sparse(X(X(:,1)==0,2:end)),'-s 0 -q');
xvalid_diff = train(Y(X(:,1)~=0),sparse(X(X(:,1)~=0,2:end)),'-s 0 -v 10 -q')
model_diff = train(Y(X(:,1)~=0),sparse(X(X(:,1)~=0,2:end)),'-s 0 -q');

for i=1:n*m,i
  I = find(stage==i);
  [lab,acc,pval] = predict(Y(I),sparse(X(I,:)),model_all,'-b 1');
  ACC(i) = acc(1);
  PVAL(I,:) = pval;
  meanPval(i) = mean(pval(:,1));
end
return;
% compute true decision error on training data:
model = model_all;
%load model
I = find(X*model.w'-model.bias<0);
load dat
%DAT = DAT(917:1839,:)
DAT = DAT(1:916,:)
load rbfmodel
%DAT = DAT(1840:end,:)
optimal = min(DAT(:,2));
for i=1:n*m
  data = DAT((i==DAT(:,1)),:);
  %v = data(:,3:end)*model.w'-model.bias;
  v = svmpredict(ones(size(data,1),1),data(:,3:end),svmodel);
  if isempty(v)
    Classify(i) = 1;
  else
    [~,idx] = max(v);
    LB(i) = data(idx,2);
    if (data(idx,2) == optimal)
      Classify(i) = 1;
    else
      Classify(i) = 0;
      [~,J]=sort(v);
      data(J,2)'
    end
  end
end
