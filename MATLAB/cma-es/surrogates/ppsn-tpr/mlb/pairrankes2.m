% Written by tpr@hi.is (ordinal regression)
% Ordinal regression evolution strategy
clear all, close all, format compact
%rand('state',0)

% parameters for the simulation
ell = 5;
lambda = 10;
n = 30; % dimensions for the problem
sigma = 1; % standard deviation of the search distribution
xp = [100 zeros(1,n-1)]; % initial starting point for progress rate simulator (the current parent point)
x = ones(lambda,1)*xp + randn(lambda,n);
yp = xp; % point where model samples are created
y = ones(ell,1)*yp + randn(ell,n);
fy = func(y);
[fy,I] = sort(fy);
y = y(I,:);
fy = fy;
ell = length(fy);

%[dummy,I] = sort(fy);
%fy(I) = (1:ell)';

% create new data set:
[y1, y2, fy12, PAIR] = createdatapair(y, fy, 1);
%for i=1:8, j = ceil(rand(1)*ell); tmp = y1(j,:); y1(j,:) = y2(j,:); y2(j,:) = tmp; fy12(j) = -fy12(j); end
m = size(y1,1)

% SVM method
G = pairkernel(y1',y2');
C = 100;
f = -ones(m,1);
Aeq = fy12';
ceq = 0;
LB = zeros(m,1);
UB = C*ones(m,1);
H = (fy12 * fy12').*G;

tic;
alpha = zeros(m,1); % initial quess of alpha
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha,1);
toc
tol = max(abs(alpha))/100000
SV = find(alpha > tol & alpha < (C-tol));
size(SV)
fest = G(:,SV)*(alpha(SV).*fy12(SV));

trainaccuracy = sum(sign(fest) == fy12)/m*100

[dummy,I] = sort(func(x));
x = x(I,:);

G1 = kernel(y1(SV,:),x);
G2 = kernel(y2(SV,:),x);
fyest = (G1-G2)'*(alpha(SV).*fy12(SV)); % + b;
[dummy,I] = sort(fyest); I'
[dummy,Itrue] = sort(func(x)); Itrue'

% check now if the best point would change the number of support vectors:
xbest = x(I(1),:);
fbest = func(xbest);

% where does this point rank with my training set?
G1 = kernel(y1(SV,:),[y;xbest]);
G2 = kernel(y2(SV,:),[y;xbest]);
fcompare = (G1-G2)'*(alpha(SV).*fy12(SV)); % + b;
[dummy,I] = sort(fcompare); I'
[dummy,Itrue] = sort([fy;fbest]); Itrue'


%return  

% now create new data paise using this new example!
ry(Itrue) = 1:length(Itrue)
mn = 0;
for i=1:ell,
  mn = mn + 1;
  yn1(mn,:) = xbest; yn2(mn,:) = y(i,:);
  fyn12(mn,1) = sign (ry(end) - ry(i));
  pair(mn,1:2) = [ell+1 i];
end
for i=1:ell,
  mn = mn + 1;
  yn2(mn,:) = xbest; yn1(mn,:) = y(i,:);
  fyn12(mn,1) = sign (-ry(end) + ry(i));
  pair(mn,1:2) = [i ell+1];
end
% reduce the data set down to the support vectors only!
PAIR = PAIR(SV,:); PAIR = [PAIR; pair];
y1 = y1(SV,:); y2 = y2(SV,:);
y1 = [y1;yn1]; y2 = [y2;yn2];
fy12 = fy12(SV); fy12 = [fy12;fyn12];

% data stripping!!!
%for i=2:m,
%  I = find ((PAIR(i-1,1) == PAIR(i:end,2)) & (PAIR(i-1,2) == PAIR(i:end,1)));
%  PAIR(i + I - 1,:) = [];
%  y1(i + I - 1, :) = [];  y2(i + I - 1, :) = [];
%  fy12(i + I - 1, :) = [];
%  if (size(PAIR,1) <= i + 1), break; end
%end

m = size(y1,1)

% SVM method
G = pairkernel(y1',y2');
C = 100;
f = -ones(m,1);
Aeq = fy12';
ceq = 0;
LB = zeros(m,1);
UB = C*ones(m,1);
H = (fy12 * fy12').*G;

tic;
alpha0 = zeros(m,1); % initial quess of alpha
alpha0(1:length(SV)) = alpha(SV);
alpha = loqo(H,f,Aeq,ceq,LB,UB,alpha0,1);
toc
tol = max(abs(alpha))/100000
SV = find(alpha > tol & alpha < (C-tol));
size(SV)
fest = G(:,SV)*(alpha(SV).*fy12(SV));

trainaccuracy = sum(sign(fest) == fy12)/m*100

% recheck the ranking
G1 = kernel(y1(SV,:),x);
G2 = kernel(y2(SV,:),x);
fyest = (G1-G2)'*(alpha(SV).*fy12(SV)); % + b;
[dummy,I] = sort(fyest); I'
[dummy,Itrue] = sort(func(x)); Itrue'

% check now if the best point would change the number of support vectors:
% take the next best
xbest = x(I(1),:);
fbest = func(xbest);

% where does this point rank with my training set?
G1 = kernel(y1(SV,:),[y;xbest]);
G2 = kernel(y2(SV,:),[y;xbest]);
fcompare = (G1-G2)'*(alpha(SV).*fy12(SV)); % + b;
[dummy,I] = sort(fcompare); I'
[dummy,Itrue] = sort([fy;fbest]); Itrue'
