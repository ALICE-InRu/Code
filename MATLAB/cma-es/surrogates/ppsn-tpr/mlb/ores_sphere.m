% ORES_SPHERE DEMO (see also banana demo)
% This demo illustrates the 
% (1,\lambda) ORES isotropic mutation
% Copyleft T.P. Runarsson 2006
clear all, close all

% Sphere function and ES parameters
xfitness = 'sum(x.^2,1)';
yfitness = 'sum(y.^2,1)';

lambda = 10;                   % number of offspring produced
n = 30;                         % problem dimension
s = 1/sqrt(n);                 % initial mean step size
varphi = 1;                    % progress rate parameter
tau = varphi/sqrt(n);          % learning rate
G = 1000;                        % maximum number of generations
x = [-1.9;zeros(n-1,1)];                  % initial point

% ordinal model
ell = 2;                      % initial model size
maxell = 30;              % maximum model size
y = x*ones(1,ell) + (s*ones(n,ell)).*randn(n,ell);

% some data for storing search history fo animation
X = x'; S = s; ALLX = [];

% start generation loop for single parent ES
for g = 2:G, g
  % we start by mutating the mean step size using the log-normal distribution
  s = s*exp(tau*randn(1,lambda));
  % the variation without rotation
  dx = (ones(n,1)*s).*randn(n,lambda);
  % finally, perform actual variation (mutation)
  x = x*ones(1,lambda) + dx;
  % keep a record of all offspring created (used for animation)
  ALLX = [ALLX; x'];
  % evalutate the fitness of these lambda individuals
  fy = eval(yfitness); fxtrue = eval(xfitness);
  % evaluate the fitness based on ordinal regression
  fx = fxtrue;
%  tiedrank(fx)
  [fx, y, fy] = ordinalregression(x, y, fy, fxtrue, 3);
%  tiedrank(fx), pause
  % select the best individual (also its step size and rotation angle)
  [F(g),i] = min(fx); x = x(:,i); s = s(i);
  % add this individual to our model file also
  x
  % if the data file is too large then remove top individual
  while (length(fy) > maxell), y(:,1) = []; fy(1) = []; end
  % keep a record of all parents created (used for animation)
  X(g,:) = x'; S(g) = s;
end

% the rest of this code is only to illustrate
% the search above using an animation

% plot the Banana function landscape contours
% and label the main parts of the figure
xx = [-2:0.125:2]';
yy = [-2:0.125:2]';
[x,y] = meshgrid(xx',yy') ;
meshd = y.^2+x.^2; 
hold off
conts = exp(3:20);
xlabel('x1'),ylabel('x2'),title('Minimization of the Sphere function')
contour(xx,yy,meshd,conts,'k:')
hold on
plot(-1.9,0,'o'), text(-1.9,0,'Start Point')
plot(0,0,'o'), text(0,0,'Solution')
grid on, axis square
% now perform the actual animation
shg
for i=1:length(X)-1,
  hndl(1) = plot(X(i,1),X(i,2),'ro');
  hndl(2) = plot(ALLX(1+(i-1)*lambda:i*lambda,1),ALLX(1+(i-1)*lambda:i*lambda,2),'.','color','r','MarkerSize',5);
  set(plot(X(i,1),X(i,2),'.'),'color',[.5 .5 .5],'MarkerSize',10);
  pause(.2)
  delete(hndl)
end
