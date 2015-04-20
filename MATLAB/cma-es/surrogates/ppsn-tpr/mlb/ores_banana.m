% ORES_BANANA DEMO (see also banana demo)
% This demo illustrates the 
% (1,\lambda) ORES using mutative self-adaptation and correlated mutation.
% Copyleft T.P. Runarsson 2006
clear all, close all
rand('seed',0); randn('seed',0)

% Banana function and ES parameters
xfitness = '100*(x(2,:)-x(1,:).^2).^2+(1-x(1,:)).^2';
yfitness = '100*(y(2,:)-y(1,:).^2).^2+(1-y(1,:)).^2';

lambda = 10;                   % number of offspring produced
n = 2;                         % problem dimension
s = 0.1*ones(n,1)/sqrt(n);     % initial mean step size
a = 0;                         % initial rotation
varphi = 1;                    % progress rate parameter
tau = varphi/sqrt(2*n);        % learning rate
tau_ = varphi/sqrt(2*sqrt(n));
G = 100;                       % maximum number of generations
x = [-1.9;2];                  % initial point

% ordinal model
ell = 2;                      % initial model size
maxell = 2*lambda;              % maximum model size
y = x*ones(1,ell) + (s*ones(1,ell)).*randn(n,ell);

funceval(1) = ell;

% some data for storing search history fo animation
X = x'; S = s'; A = a; ALLX = [];

% start generation loop for single parent ES
for g = 2:G, g
  % we start by mutating the mean step size using the log-normal distribution
  sold = s;
  s = (s*ones(1,lambda)).*exp(tau*ones(n,1)*randn(1,lambda)+tau_*randn(n,lambda));
  % then we mutate the angle by 5 degrees
  aold = a;
  a = a*ones(1,lambda) + randn(1,lambda)*5/180*pi; a = 0*a;
  % the variation without rotation
  dxt = s.*randn(n,lambda);
  % now rotate the variation
  dx(1,:) = dxt(1,:).*cos(a) - dxt(2,:).*sin(a);
  dx(2,:) = dxt(1,:).*sin(a) + dxt(2,:).*cos(a);
  % finally, perform actual variation (mutation)
  x = x*ones(1,lambda) + dx;
  % keep a record of all offspring created (used for animation)
  ALLX = [ALLX; x'];
  % evalutate the fitness of these lambda individuals
  fy = eval(yfitness); fxtrue = eval(xfitness);
  % evaluate the fitness based on ordinal regression
  fx = fxtrue;
%  tiedrank(fx)
  [fx, y, fy, funceval(g)] = ordinalregression(x, y, fy, fxtrue, lambda);
%  tiedrank(fx), pause
  % select the best individual (also its step size and rotation angle)
  [F(g),i] = min(fx); x = x(:,i); s = s(:,i); a = a(:,i);
%  a = aold + 0.2*(a-aold);  s = sold + 0.2*(s-sold);
  % add this individual to our model file also
  x
  % if the data file is too large then remove top individual
  while (length(fy) > maxell), y(:,1) = []; fy(1) = []; end
  % keep a record of all parents created (used for animation)
  X(g,:) = x'; S(g,:) = s'; A(g,1) = a;
end

% the rest of this code is only to illustrate
% the search above using an animation

% plot the Banana function landscape contours
% and label the main parts of the figuxx = [-2:0.125:2]';
yy = [-1:0.125:3]';
[x,y] = meshgrid(xx',yy') ;
meshd = 100.*(y-x.*x).^2 + (1-x).^2; 
hold off
conts = exp(3:20);
xlabel('x1'),ylabel('x2'),title('Minimization of the Banana function')
contour(xx,yy,meshd,conts,'k:')
hold on
plot(-1.9,2,'o'), text(-1.9,2,'Start Point')
plot(1,1,'o'), text(1,1,'Solution')

% now perform the actual animation
shg
dxy = [1 0;0 1; -1 0; 0 -1];
for i=1:length(A)-1,
  a = A(i,1);
  for j=1:4,
    dxt = 2*(S(i,:).*dxy(j,:));
    dX(j,1) = dxt(1).*cos(a) - dxt(2).*sin(a);
    dX(j,2) = dxt(1).*sin(a) + dxt(2).*cos(a);
  end
  hndl(1) = plot(X(i,1)+dX([1 3],1),X(i,2)+dX([1 3],2),'r--');
  hndl(2) = plot(X(i,1)+dX([2 4],1),X(i,2)+dX([2 4],2),'r--');
  hndl(3) = plot(X(i,1),X(i,2),'ro');
  hndl(4) = plot(ALLX(1+(i-1)*lambda:i*lambda,1),ALLX(1+(i-1)*lambda:i*lambda,2),'.','color','r','MarkerSize',5);
  set(plot(X(i,1),X(i,2),'.'),'color',[.5 .5 .5],'MarkerSize',10);
  pause(.25)
  delete(hndl)
end
re
