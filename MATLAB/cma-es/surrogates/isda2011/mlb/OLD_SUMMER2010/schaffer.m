function [f] = schaffer(x),
% SCHAFFER
% example:
% [xb,a,b,eta] = ndnies('schaffer','min',[-50 -50; 50 50],200,200,20,1,3) ;
% f = schaffer(xb); 
% plot(f(:,1),f(:,2),'o')
% hold on, % not plot the true front:
% plot(0:0.01:4,(sqrt(0:0.01:4)-2).^2)
  
  f(:,1) = x(:,1).^2 + x(:,2).^2;
%   f(:,2) = (x(:,1) + 2).^2 + x(:,2).^2;
  
  
  