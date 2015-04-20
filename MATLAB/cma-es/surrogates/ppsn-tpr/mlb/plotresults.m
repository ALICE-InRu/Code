% script for plotting simulation results

%warning off

clear all, close all

batchsize = [5 7 9 11];

ignore = inf;

fcn = { 'sphere', 'rosen', 'rastrigin'};

dim = [2 5 10 20]

kernel = {'p2', 'p4', 'r1'}

lstyle = {'k--', 'k-.', 'k:'}

for i = 1, % the functio type
  if (1 == strcmp(fcn{i}, 'rosen'))
    xupper = [800 1300 3500 16000];  
    ylower = [1E-6 1E-1 1E-0 1E-0];  
    yupper = [10 100 1000 1000 ];  
    myxticks{1}.xticks = [200 400 600];
    myxticks{2}.xticks = [200 600 1000];
    myxticks{3}.xticks = [1000 2000 3000];
    myxticks{4}.xticks = [4000 8000 12000];
  elseif  (1 == strcmp(fcn{i}, 'sphere'))
    xupper = [200 700 1400 3000];  
    ylower = [1E-6 1E-6 1E-8 1E-8 ];  
    yupper = [1 10 10 100];  
    myxticks{1}.xticks = [100 200];
    myxticks{2}.xticks = [200 400 600];
    myxticks{3}.xticks = [200 600 1000];
    myxticks{4}.xticks = [500 1500 2500];
  else
    xupper = [1000 2700 8000 20000];  
  end
  for j = 1:4, % the dimension
    subplot(2,2,j)
    hold off
    [gc, fc] = getstats2(['clean' fcn{i} num2str(dim(j))], batchsize(j), ignore);
    sfc = smooth(gc, fc);
    h = semilogy(gc, sfc, 'k-');
    hold on
    for k = 1:3, % the kernel type
      fcn{i}, dim(j), kernel{k}
      [g, f] = getstats2([kernel{k} fcn{i} num2str(dim(j))], batchsize(j), ignore);
      sf = smooth(g, f);
      semilogy(g, sf, lstyle{k});
    end
    set(gca,'xlim',[1 xupper(j)])
    set(gca,'ylim',[ylower(j) yupper(j)])
    set(gca,'xminorticks','on','yminorticks','on')
    set(gca,'xtick',myxticks{j}.xticks)
    if (j == 4)
      legend('CMAES','Poly-2','Poly-4','RBF-1','Location','NorthEast')
    end
    if (j == 1) | (j == 3)
      ylabel('mean fitness')
    end
    if (j == 2) | (j == 4)
      set(gca,'position',get(gca,'position')-[0.05 0 0 0])
    end
    if (j == 3) | (j == 4)
      set(gca,'position',get(gca,'position')+[0 0.05 0 0])
      xlabel('function evaluations')
    end
    title(['n=' num2str(dim(j))])
  end
end

%set(gca,'ylim',[1e-10 10])
%set(gca,'xlim',[1 1000])

%warning on
