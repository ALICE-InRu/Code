function [varphi, varphimedian, varphistd, meanfcneval] = prateores(xopt,x,lambda,sigma,M,factor)
% PRATEORES isotropic rate of progress in terms of distance to optimum
%
% varphi = prateores(xopt,x,lambda,sigma,M,factor);
% example:
% [varphi, varphimedian, varphistd, meanfcneval] = prateores(zeros(100,1),[100;zeros(99,1)],[5 10],[0.25:0.25:5],10000,2);
% plot([0:0.25:5],varphi,'+'); hold on
% for i=1:size(varphi,1),varphicurve(i,:)=interp1([0:0.25:5],varphi(i,:),[0:0.1:5],'cubic'); end
% plot([0:0.1:5],varphicurve); set(gca,'ylim',[-0.7 2.6]);
%
% or by hand:
% x = [0:0.5:5]' ; X = [x.^2 x ones(length(x),1)] ; x = [0:0.1:5]' ;
% for i=1:size(varphi,1), a(:,i) = X\varphi(i,:)' ; varphicurve(i,:)=(a(1,i)*x.^2+a(2,i)*x+a(3,i)*ones(length(x),1))' ; end
% 
% note: this is for a (1,\lambda) strategy

n = length(xopt);
r = sqrt(sum((x-xopt).^2));
for i=1:length(lambda),
  for j=1:length(sigma),[i j], % echo status
    eta = sigma(j)*r/n;
    for k=1:M,
%      y = x*ones(1,lambda(i)) + eta*randn(n,lambda(i)); f = func(y); [f,I] = sort(f); ybest = y(:,I(1));
      [fybest, ybest,fcneval(k)] = oresprog(x, eta, factor*lambda(i), 2, factor*lambda(i), lambda(i));
      vp(k) = r-sqrt(sum((ybest-xopt).^2));
    end
    varphi(i,j) = n*mean(vp)/r;
    varphimedian(i,j) = n*median(vp)/r;
    varphistd(i,j) = n*std(vp)/r;
    meanfcneval(i,j) = mean(fcneval);
  end
end

