% Ordinal regression according to John Shawe-Taylor and Nello Christianini
clear all, close all, format compact
rand('state',0)

% generate ell examples on a plane
ell = 10;
x1 = rand(ell,1); x2 = rand(ell,1);
F = 10 * ((x1 - 0.5) + 10 * (x2 - 0.5));

[F,I] = sort(F);
x1 = x1(I); x2 = x2(I);

p = 5;
%theta = [-inf, -1, -0.1, 0.25, 1, inf];
theta = [-inf, F(ell/p:(ell/p):(end-(ell/p)))', inf]
length(theta)
%r = 1:length(theta);

X = [x1 x2];
n = 2;

% determine the true rank of the training set
for i = 1:ell,
  rnk = find(F(i) > theta);
  y(i,1) = rnk(end);
end
y = (1:length(F))'

% plot the data on a 2-d plane
colors = 'bgryckm';
hold off
for rnk = 1:(length(theta)-1),
  rnkind{rnk}.I = find(y == rnk);
%  plot(x1(rnkind{rnk}.I), x2(rnkind{rnk}.I), [colors(rnk) '.']);
%  hold on
end
%axis square, xlabel('{x_1}'); ylabel('{x_2}');

% nu-SVM method
nu = 0.000001;
G = X*X'; % (X*X' + 1).^2; % kernel matrix
H = [G -G;-G G];
C = 10;
f = zeros(2*ell,1);
A = zeros(1,2*ell);
c = 0;
Aeq(1,:) = ones(1,2*ell);
ceq(1,1) = 1;
% now go through all the rankings
for yr = 2:max(y),
  I = find(y==(yr-1));
  J = find(y==yr);
  Aeq(yr,I) = ones(1,length(I));
  Aeq(yr,ell + J) = -ones(1,length(J));
  ceq(yr,1) = 0;
end
LB = zeros(2*ell,1);
UB = ones(2*ell,1)/(nu*ell);

tic;
alphapalpham = zeros(2*ell,1); % initial quess of alpha
%alphapalpham = quadprog(H,f,A,c,Aeq,ceq,LB,UB,alphapalpham);
alphapalpham = loqo(H,f,Aeq,ceq,LB,UB,alphapalpham,1);
toc
alpha = alphapalpham(1:ell) - alphapalpham(ell+1:2*ell);
SV = find(alpha > 0.0001 & alpha < (1/(nu*ell)));
fest = G*alpha; % + b*ones(m,1);

plot(fest)
%trainaccuracy = sum(sign(fest) == y)/ell*100

return;


% determine the true rank of the training set
for i = 1:ell,
  rnk = find(festx(i) > theta);
  yest(i,1) = rnk(end);
end

% determine the theta levels
for rnk = 1:4,
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
  G1k = kernel(X1,X1(k,:));
  G2k = kernel(X2,X1(k,:));
  fk1 = (G1k-G2k)'*(alpha.*Y); % + b;
  G1k = kernel(X1,X2(k,:));
  G2k = kernel(X2,X2(k,:));
  fk2 = (G1k-G2k)'*(alpha.*Y); % + b;
  flevel(rnk) = (fk1 + fk2)/2;
  set(plot([X1(k,1) X2(k,1)], [X1(k,2) X2(k,2)],'k-'),'linewidth',2);
end

% plot the boundaties in f(x) space.
figure(2), clf
plot(festx), hold on
for rnk = 1:4,
  plot([1 ell],[flevel(rnk) flevel(rnk)],'g--')
end

% actually rank the data!
yest = zeros(ell,1);
flevels = [-inf flevel inf];
for rnk = 1:5,
 inx = find((flevels(rnk+1) >= festx) & (festx > flevels(rnk)));
 yest(inx) = rnk;
end

plot([y yest+0.2],'.')
accuracy = sum(y==yest)/length(y)*100

% put circle around the points that were incorrectly classified!
I = find(y ~= yest);
figure(1);
set(plot(X(I,1),X(I,2),'ko'),'markersize',6);
