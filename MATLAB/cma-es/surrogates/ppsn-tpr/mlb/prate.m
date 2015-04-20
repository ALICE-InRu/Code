function varphi = prate(fcn,xopt,x,lambda,sigma,M)
% PRATE isotropic rate of progress in terms of distance to optimum
%
% varphi = prate(func,xopt,x,lambda,sigma,M);
% example:
% varphi = prate('f01',zeros(1,100),[100 zeros(1,99)],[1 2 5 10 100],[0:0.25:5],10000);
% plot([0:0.25:5],varphi,'+'); hold on
% for i=1:size(varphi,1),varphicurve(i,:)=interp1([0:0.25:5],varphi(i,:),[0:0.1:5],'cubic'); end
% plot([0:0.1:5],varphicurve); set(gca,'ylim',[-0.7 2.6]);
%
% or by hand:
% x = [0:0.5:5]' ; X = [x.^2 x ones(length(x),1)] ; x = [0:0.1:5]' ;
% for i=1:size(varphi,1), a(:,i) = inv(X'*X)*X'*varphi(i,:)' ; varphicurve(i,:)=(a(1,i)*x.^2+a(2,i)*x+a(3,i)*ones(length(x),1))' ; end
% 
% note: this is for a (1,\lambda) strategy

n = length(xopt);
r = sqrt(sum((x-xopt).^2));
for i=1:length(lambda),
  for j=1:length(sigma),[i j], % echo status
    eta = sigma(j)*r/n;
    for k=1:M,
      y = ones(lambda(i),1)*x + eta*randn(lambda(i),n);
      f = feval(fcn,y);
      [f,I] = sort(f);
      vp(k) = r-sqrt(sum((y(I(1),:)-xopt).^2));
    end
    varphi(i,j) = n*mean(vp)/r;
  end
end

