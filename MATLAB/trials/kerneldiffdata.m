clear all, close all
problems  = getproblem('../rawData/j.rnd.10x10.train.txt');

DAT = [];
for IDNUM = 4
  DAT = [DAT;generate_data(problems(IDNUM).p,problems(IDNUM).sigma)];
end

optimal = min(DAT(:,2));
data_opt = [];
data_sub = [];
[n m] = size(problems(IDNUM).p);
for i=1:n*m
  data = DAT((i==DAT(:,1)),:);
  optidx = find(data(:,2) == optimal);
  subidx = find(data(:,2) ~= optimal);
  for j=1:length(optidx)
    for k=1:length(subidx)
      data_opt = [data_opt;data(optidx(j),3:end)];
      data_sub = [data_sub;data(subidx(k),3:end)];
    end
  end
end

y = ones(length(data_opt),1);
G = pairkernel(data_opt',data_sub');

%X = [diff_data;-diff_data];
%Y = [y;-y];
%X = [diff_data];
Y = [y];
m = length(Y)
C = 1000000;
f = -ones(m,1);
A = zeros(1,m);
c = 0;
Aeq = Y';
ceq = 0;
LB = zeros(m,1);
UB = C*ones(m,1);
H = (Y*Y').*(G + (1/C)*eye(m));
tic;
alpha = zeros(m,1); % initial quess of alpha
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,0,1);
toc

tol = abs(alpha)*0.001;
SV = find(alpha > tol & alpha < (C-tol));
b = ( 1./Y(SV) - G(SV,:)*(alpha.*Y) );
b = mean(b)

fest = G*(alpha.*Y) + b*ones(m,1);

trainaccuracy = sum(sign(fest) == Y)/m*100

return

optimal = min(DAT(:,2));
for i=1:n*m
  data = DAT((i==DAT(:,1)),:);
  v = data(:,3:end)*model.w'-model.bias;
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
