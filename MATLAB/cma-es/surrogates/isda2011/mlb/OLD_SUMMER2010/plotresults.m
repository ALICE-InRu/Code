% script for plotting simulation results
clear all, close all

strfitnessfct='frosen';
for i=1:4*2, tmpname{i}=sprintf(['matResults/' strfitnessfct '%d.mat'],i); end, m=0;

dim = [2 5 10 20];

plotmeanfitness=1; plotmeaninterm=0;

lstyle = {'k:', '', '', '', '', 'k-', 'k--'};

  for j = 1:length(dim), % the dimension
    subplot(2,2,j)
    N=dim(j); 
    hold on
    for T = [1,6], % model type
      m=m+1;
      load(tmpname{m})
      if plotmeanfitness
        semilogy(funcEvals(1:end-1), smoothFitness(1:end-1), lstyle{T});
      elseif plotmeaninterm
        semilogy(generation(1:end-1), smoothIntmEval(1:end-1), lstyle{T});
      end
    end
    if (j == 4)
      legend('Org.','New','Location','SouthEast')
    end
    if (j == 1) | (j == 3)
      if plotmeanfitness
        ylabel('mean fitness')
      elseif plotmeaninterm
        ylabel('mean interm. func. evals.')
      end
    end
    if (j == 2) | (j == 4)
      set(gca,'position',get(gca,'position')-[0.05 0 0 0])
    end
    if (j == 3) | (j == 4)
      set(gca,'position',get(gca,'position')+[0 0.05 0 0])
      xlabel('# function evaluations')
    end
    title(['n=' num2str(dim(j))])
  end

