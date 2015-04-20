% Written by tpr@hi.is (ordinal regression)
% Ordinal regression evolution strategy

clear all, close all, format compact
rand('state',0)

% paremeters for the simulation
ell = 100;
lambda = 10;
n = 30; % dimensions for the problem
sigma = 1; % standard deviation of the search distribution
xp = [100 zeros(1,n-1)]; % initial starting point for progress rate simulator (the current parent point)
x = ones(lambda,1)*xp + randn(lambda,n);
yp = xp; % point where model samples are created
y = ones(ell,1)*yp + randn(ell,n);
fy = func(y);
[fy,I] = sort(fy);
y = y(I(1:10:ell),:);
fy = fy(1:10:ell);
ell = length(fy);

% create new data set:
m = 0;
for rnk = 1:ell,
  classes = 1:ell; 
  classes(rnk) = [];
  for k = classes,
    % generate a random sample of type rnk
    i = rnk;
    j = k;
    % now generate the data vector:
    m = m + 1;
    y1(m,:) = y(i,:); y2(m,:) = y(j,:);
    fy12(m,1) = sign (fy(i) - fy(j));
    PAIR(m,1:2) = [i j];
  end
end

% SVM method
for i = 1:m,
  for j = 1:m,
    k1 = kernel(y1(i,:),y1(j,:));
    k2 = kernel(y1(i,:),y2(j,:));
    k3 = kernel(y2(i,:),y1(j,:));
    k4 = kernel(y2(i,:),y2(j,:));
    G(i,j) = k1 - k2 - k3 + k4;
  end
end
C = 10;
f = -ones(m,1);
A = zeros(1,m);
c = 0;
Aeq = fy12';
ceq = 0;
LB = zeros(m,1);
UB = C*ones(m,1);
H = (fy12*fy12').*(G + (1/C)*eye(m));

tic;
alpha = zeros(m,1); % initial quess of alpha
%alpha = quadprog(H,f,A,c,Aeq,ceq,LB,UB,alpha);
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,1);
toc
delta = max(abs(alpha))/100000;
SV = find(alpha > delta & alpha < (C-delta));
size(SV)
%b = ( 1./Y(SV) - G(SV,:)*(alpha.*Y) );
%b = mean(b)
fest = G*(alpha.*fy12); % + b*ones(m,1);

trainaccuracy = sum(sign(fest) == fy12)/m*100

[dummy,I] = sort(func(x));
x = x(I,:);

G1 = kernel(y1,x);
G2 = kernel(y2,x);
fyest = (G1-G2)'*(alpha.*fy12); % + b;
[dummy,I] = sort(fyest); I'

% check now if the best point would change the number of support vectors:
xbest = x(I(1),:);
fbest = func(xbest);

% where does this point rank with my training set?
% concat this example to our data set and generate some
% more training pair with this example
ell = ell + 1;
y = [y;xbest];
fy = [fy;fbest];
for rnk = 1:ell,
  classes = 1:ell; 
  classes(rnk) = [];
  for k = classes,
    % generate a random sample of type rnk
    i = rnk;
    j = k;
    % now generate the data vector:
    m = m + 1;
    y1(m,:) = y(i,:); y2(m,:) = y(j,:);
    fy12(m,1) = sign (fy(i) - fy(j));
    PAIR(m,1:2) = [i j];
  end
end

% SVM method
for i = 1:m,
  for j = 1:m,
    k1 = kernel(y1(i,:),y1(j,:));
    k2 = kernel(y1(i,:),y2(j,:));
    k3 = kernel(y2(i,:),y1(j,:));
    k4 = kernel(y2(i,:),y2(j,:));
    G(i,j) = k1 - k2 - k3 + k4;
  end
end
C = 10;
f = -ones(m,1);
A = zeros(1,m);
c = 0;
Aeq = fy12';
ceq = 0;
LB = zeros(m,1);
UB = C*ones(m,1);
H = (fy12*fy12').*(G + (1/C)*eye(m));

tic;
alpha = zeros(m,1); % initial quess of alpha
%alpha = quadprog(H,f,A,c,Aeq,ceq,LB,UB,alpha);
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,1);
toc

tol = max(abs(alpha))/1000;
SV = find(alpha > tol & alpha < (C-tol));
size(SV)
%b = ( 1./Y(SV) - G(SV,:)*(alpha.*Y) );
%b = mean(b)
fest = G*(alpha.*fy12); % + b*ones(m,1);

trainaccuracy = sum(sign(fest) == fy12)/m*100
[dummy,I] = sort(func(x));
x = x(I,:);

G1 = kernel(y1,x);
G2 = kernel(y2,x);
fyest = (G1-G2)'*(alpha.*fy12); % + b;
[dummy,I] = sort(fyest); I'
