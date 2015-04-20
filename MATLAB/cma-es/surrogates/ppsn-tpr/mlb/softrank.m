% Ordinal regression according to John Shawe-Taylor and Nello Christianini
clear all, close all, format compact
rand('state',0)

% generate ell examples on a plane
ell = 10;
x1 = rand(ell,1); x2 = rand(ell,1);
F = 10 * ((x1 - 0.5) + 10 * (x2 - 0.5));

% sort them
[F,I] = sort(F); x1 = x1(I); x2 = x2(I);

% the training data vector
y = (1:length(F))'; % each example in one rank (note F is sorted!)
X = [x1 x2];

% nu-SVM method
nu = 0.00001;
G = X*X'; % (X*X' + 1).^2; % kernel matrix
H = [G -G;-G G];
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