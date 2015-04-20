% Written by tpr@hi.is (ordinal regression)
% Ordinal regression example

clear all, close all, format compact
rand('state',0)

ell = 10;
x1 = rand(ell,1); x2 = rand(ell,1);
F = 10 * ((x1 - 0.5) + 10 * (x2 - 0.5));

[F,I] = sort(F);
x1 = x1(I); x2 = x2(I);

y = (1:length(F))';
X = [x1 x2];
n = 2;

colors = 'bgryckmbgryckmbgryckmbgryckm';
for rnk = 1:max(y),
  rnkind{rnk}.I = find(y == rnk);
end

% create new data set:
m = 0;
for rnk = 1:max(y),
  classes = 1:max(y); classes(rnk) = [];
  for p = 1:1,
    for k = classes,
      % generate a random sample of type rnk
      i = rnkind{rnk}.I(ceil(rand(1) * length(rnkind{rnk}.I)));
      j = rnkind{k}.I(ceil(rand(1) * length(rnkind{k}.I)));
      % now generate the data vector:
      m = m + 1;
      X1(m,:) = X(i,:); X2(m,:) = X(j,:);
      Y(m,1) = sign (y(i) - y(j));
      CL(m,1:2) = [rnk k];
      plot(X(i,1), X(i,2), [colors(rnk) '.']);
      hold on
      plot(X(j,1), X(j,2), [colors(k) '.']);
    end
  end
end
axis square, xlabel('{x_1}'); ylabel('{x_2}');

% SVM method
for i = 1:m,
  for j = 1:m,
    k1 = kernel(X1(i,:),X1(j,:),2);
    k2 = kernel(X1(i,:),X2(j,:),2);
    k3 = kernel(X2(i,:),X1(j,:),2);
    k4 = kernel(X2(i,:),X2(j,:),2);
    G(i,j) = k1 - k2 - k3 + k4;
  end
end

% G = X*X'; % kernel matrix
C = 10;
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
%alpha = quadprog(H,f,A,c,Aeq,ceq,LB,UB,alpha);
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,1);
toc

SV = find(alpha > 0.0001 & alpha < (C-0.0001));
b = ( 1./Y(SV) - G(SV,:)*(alpha.*Y) );
b = mean(b)
fest = G*(alpha.*Y); % + b*ones(m,1);

trainaccuracy = sum(sign(fest) == Y)/m*100

% lets plot the support vectors that define the boundary!
for i = 1:length(SV),
  plot([X1(SV(i),1) X2(SV(i),1)], [X1(SV(i),2) X2(SV(i),2)],'k:');
end

G1 = kernel(X1,X,2);
G2 = kernel(X2,X,2);
festx = (G1-G2)'*(alpha.*Y); % + b;

% determine the theta levels
for rnk = 1:max(y)-1,
  inxs = find( ((CL(SV,1) == rnk) & (CL(SV,2) == (rnk + 1))) | ...
               ((CL(SV,2) == rnk) & (CL(SV,1) == (rnk + 1))) );
  if isempty(inxs), 
    disp(sprintf('boundary %d-%d not available', rnk,rnk+1)); 
    CL(SV,:)
  % try to find a pair that is not in the support vector set
    inxs = find( ((CL(:,1) == rnk) & (CL(:,2) == (rnk + 1))) | ...
                 ((CL(:,2) == rnk) & (CL(:,1) == (rnk + 1))) );
    [dummy,k] = min(abs(fest(inxs))); k
  else
    fest(SV(inxs));
    [dummy,inx] = min(abs(fest(SV(inxs))));
    k = SV(inxs(inx))
  end
  G1k = kernel(X1,X1(k,:),2);
  G2k = kernel(X2,X1(k,:),2);
  fk1 = (G1k-G2k)'*(alpha.*Y); % + b;
  G1k = kernel(X1,X2(k,:),2);
  G2k = kernel(X2,X2(k,:),2);
  fk2 = (G1k-G2k)'*(alpha.*Y); % + b;
  flevel(rnk) = (fk1 + fk2)/2;
  set(plot([X1(k,1) X2(k,1)], [X1(k,2) X2(k,2)],'k-'),'linewidth',2);
end

% plot the boundaties in f(x) space.
figure(2), clf
plot(festx), hold on
for rnk = 1:max(y),
  plot([1 ell],[flevel(rnk) flevel(rnk)],'g--')
end

% actually rank the data!
yest = zeros(ell,1);
flevels = [-inf flevel inf];
for rnk = 1:max(y),
 inx = find((flevels(rnk+1) >= festx) & (festx > flevels(rnk)));
 yest(inx) = rnk;
end

plot([y yest+0.2],'.')
accuracy = sum(y==yest)/length(y)*100

% put circle around the points that were incorrectly classified!
I = find(y ~= yest);
figure(1);
set(plot(X(I,1),X(I,2),'ko'),'markersize',6);
