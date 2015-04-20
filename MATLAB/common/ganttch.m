function MakeSpan = ganttch(X, p, sigma, pType)
% GANTTCH Ganttchart
% usage: ganttch(X,p,sigma,pType) ;
% where: X is the starting times for the machines to be plotted
%        p is the TimeTable
%        pType is a plot type: either 'text' or 'patch'

  if nargin < 4, pType = 'none' ; end
    
  [NrJobs,NrMachines] = size(X);
  MakeSpan = 0;
  if (strcmp(pType(1),'t') || strcmp(pType(1),'p'))
    hold on
    colour = hot(NrJobs);
    set(gca,'Color',[1 1 1]/2);
  end
  for job = 1:NrJobs
    for a = 1:NrMachines
      MAC = sigma(job,a);
      StartPro = X(job,MAC);
      EndPro = X(job,MAC)+p(job,MAC);
      MakeSpan = max(MakeSpan, EndPro);
      dM =0.4 + rand(1)/10;
      if strcmp(pType(1),'t'),
        plot([StartPro EndPro EndPro StartPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM MAC-dM],'w:');
        h = text(mean([StartPro EndPro]),MAC,sprintf('%d',job));
        set(h,'fontsize',6,'HorizontalAlignment','center');
      elseif strcmp(pType(1),'p'),
        patch([StartPro EndPro EndPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM],colour(job,:),'EdgeColor',[1 1 1]);
      else
      end
    end
  end
  if (strcmp(pType(1),'t') || strcmp(pType(1),'p'))
    title(sprintf('Ganttchart (makespan=%4.2f)',MakeSpan));
    xlabel('Time');
    ylabel('Machine');
    set(gca,'Ylim',[0 NrMachines+1],'YTick',1:NrMachines);
  end