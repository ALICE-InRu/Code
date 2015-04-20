% Generate figure for different kernels and spherical landscapes
clear all, %close all
rand('seed',0); randn('seed',0)

plotme = 2;

xx = [0:0.05:1.5]; yy = [0:0.05:1.5];
[x,y] = meshgrid(xx,yy);

f = 10*x.^2+y.^2;
f = 100*(y-x.^2).^2+(1-x).^2;
conts = exp(3:20);

%f = f/max(abs(f(:)));
%conts = [0.0001 0.001 0.01 0.1 1]

if (plotme > 1)
  hold off
  xlabel('x1'),ylabel('x2'),title('Minimization of the Banana function')
  contour(xx,yy,f,conts,'k-')
  hold on
  axis square
end

z = ones(2,60) + 0.1*randn(2,60);
[scalefac, offset] = svm_scale(z)
%scalefac = [1;1]; offset = -[1;1];
fz = 100*(z(2,:)-z(1,:).^2).^2+(1-z(1,:)).^2;
%[fz,I] = sort(fz); z = z(:,I);
sz = svm_scale(z, scalefac, offset);
[sz1, sz2, fz12, Pair] = createdatapair(sz, fz); m = length(fz12),
[z1, z2, fz12, Pair] = createdatapair(z, fz); m = length(fz12)

alpha = zeros(m,1); C = 1000000;
% ordinal support vector regression
[alpha, Sv, trainaccuracy, K] = svm_pair(sz1, sz2, fz12, C, alpha);
trainaccuracy

% do some cross validation:
xt = ones(2,1000) + 0.1*randn(2,1000);
fxt = 100*(xt(2,:)-xt(1,:).^2).^2+(1-xt(1,:)).^2;
fxtest = svm_predict(svm_scale(xt,scalefac, offset), sz1(:,Sv), sz2(:,Sv), alpha(Sv), fz12(Sv));
kentau = kendalltau(fxt,fxtest)

% now do a prediction for unknown population of sample points
for i=1:length(xx),
  for j = 1:length(yy),
    xest = svm_scale([xx(i);yy(j)],scalefac, offset);
    fxest(j,i) = svm_predict(xest, sz1(:,Sv), sz2(:,Sv), alpha(Sv), fz12(Sv));
  end
end

fxest = fxest/max(abs(fxest(:)))

if (plotme > 0)
  contour(xx,yy,fxest,'k-.')
  set(gca,'xminortick','on','yminortick','on')
%  set(gca,'yticklabel',[])
  set(gca,'xtick',[-1 0 1])
  set(gca,'ytick',[-1 0 1])
end

% plot the support vectors only
for i=1:length(Sv),
  % it may not exist previously:
  exist = 0;
  for j=i+1:length(Sv),
    if all(Pair(1:2,Sv(i)) == Pair(2:-1:1,Sv(j)))
        exist = 1;
        break;
    end
  end
  if ~exist,
%    set(plot([z1(1,Sv(i)) z2(1,Sv(i))],[z1(2,Sv(i)) z2(2,Sv(i))],'k:'),'color',[1 1 1]/2); 
  end
end
if (plotme > 1)
  plot(z1(1,:),z1(2,:),'ko')
%  plot(z1(1,:),z1(2,:),'k*')
  plot(z1(1,Sv),z1(2,Sv),'k*')
end

set(gca,'fontsize',16); xlabel('xlabel'); 
ylabel('ylabel')