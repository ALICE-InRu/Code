function plotLevels(pLevels,fx)

figure(1), clf, hold on
for i=1:length(pLevels)
  plot(fx(i,1),'k.')
  text(fx(i,1),num2str(pLevels(i)),'FontSize',8)
  text(fx(i,1)+100,num2str(i),'FontSize',8,'color','red')

%   plot(fx(i,1),fx(i,2),'k.')
%   text(fx(i,1),fx(i,2),num2str(pLevels(i)),'FontSize',8)
%   text(fx(i,1)+100,fx(i,2),num2str(i),'FontSize',8,'color','red')
end
title('Old regression')
end