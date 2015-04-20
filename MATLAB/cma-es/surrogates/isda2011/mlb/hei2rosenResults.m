clear all, close all
ignore=Inf;
scrsz = get(0,'ScreenSize');
figure('Name','Rosenbrock','Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])
subplot(4,2,8), hold on 
plot(0,8,'-r'), plot(0,8,'-b');
plot(0,8,'-','Color',[1 0.8 0.8]), plot(0,8,'-','Color',[0.8 0.8 1]);
legend('Sort all', 'Mean','Sort \mu best') 


M=2; m=0;
stopfitness=1e-5
disp('m Rosen Dim Mean Median Std K LocMin')
for N=[2 5 10 20]
  for T=[1 6]
    m=m+1;
    fname=sprintf(['matResults/rosen%d_d%d.mat'],T,N);
    [generation, intmEval, funcEvals, fitness] = getstats3(fname);
%    plotta(Stats,100,FCNEVAL,T,N,m,M,'light');
    %rosen(1:100,m)=totEval;
    %outlaw{m}=(find(minima>stopfitness));
    fprintf('%d %d %d %.2f %.2f %.2f %d %d\n',m,T,N,meanEval,medianEval,stdEval,K,length(outlaw{m}))
  end
end
m=0;
for N=[2 5 10 29]
   for T=[1,6]
%      plotta(asdf,'dark'); 
   end
end
