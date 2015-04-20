% Generate figure for different kernels and spherical landscapes
clear all, %close all
rand('seed',0); randn('seed',0)

plotme = 2;

xx = [-1.5:0.1:1.5]; yy = [-1.5:0.1:1.5];
[x,y] = meshgrid(xx,yy);

f = 100*(y-x.^2).^2+(1-x).^2;

%f = f/max(abs(f(:)));
%conts = [0.0001 0.001 0.01 0.1 1]
conts = exp(3:20);

if (plotme > 1)
  hold off
  xlabel('x1'),ylabel('x2'),title('Minimization of the Banana function')
  contour(xx,yy,f,conts,'k:')
  hold on
  axis square
end

%z = ones(2,60) + 0.1*randn(2,60);
z = randn(2,60);
[scalefac, offset] = svm_scale(z)
%scalefac = [1;1]; offset = -[1;1];
fz = 10*z(1,:).^2+z(2,:).^2;
fz = 100*(z(2,:)-z(1,:).^2).^2+(1-z(1,:)).^2;
sz = svm_scale(z, scalefac, offset);
[sz1, sz2, fz12, Pair] = createdatapair(sz, fz); m = length(fz12)
[z1, z2, fz12, Pair] = createdatapair(z, fz); m = length(fz12)

C = 1000000;
% ordinal support vector regression
[model, trainaccuracy] = svm_libsvm(sz1, sz2, fz12, C);
trainaccuracy,

% do some cross validation:
%xt = ones(2,1000) + 0.1*randn(2,1000);
xt = randn(2,1000);
fxt = 100*(xt(2,:)-xt(1,:).^2).^2+(1-xt(1,:)).^2;
fxtest = svm_predictlibsvm(svm_scale(xt,scalefac, offset), sz1, sz2, model, fz12);
size(fxt), size(fxtest)
kentau = kendalltau(fxt,fxtest)

% now do a prediction for unknown population of sample points
for i=1:length(xx),
  for j = 1:length(yy),
    xest = svm_scale([xx(i);yy(j)],scalefac, offset);
    fxest(j,i) = svm_predictlibsvm(xest, sz1, sz2, model, fz12);
  end
end

fxest = fxest/max(abs(fxest(:)))

if (plotme > 0)
  contour(xx,yy,fxest,'k-')
  set(gca,'xminortick','on','yminortick','on')
%  set(gca,'yticklabel',[])
  set(gca,'xtick',[-1 0 1])
  set(gca,'ytick',[-1 0 1])
end

% plot the support vectors only
if (plotme > 1)
  plot(z1(1,:),z1(2,:),'ko')
%  plot(z1(1,:),z1(2,:),'k*')
  plot(z1(1,:),z1(2,:),'k*')
end

set(gca,'fontsize',16); xlabel('xlabel'); 
%ylabel('ylabel')