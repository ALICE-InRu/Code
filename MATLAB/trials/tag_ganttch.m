function MakeSpan = tag_ganttch(X, p, sigma, pType, fixedjobmac, jobdispatched)
% GANTTCH Ganttchart
% usage: ganttch(X,p,sigma,pType,jobmac) ;
% where: X is the starting times for the machines to be plotted
%        p is the TimeTable
%        pType is a plot type: either 'text' or 'patch'

if nargin < 4, pType = 'none' ; end
seed = rand('seed'); % to make all random effects the same
rand('seed', 42);
[NrJobs,NrMachines] = size(X);
MakeSpan = 0;
if (strcmp(pType(1),'t') || strcmp(pType(1),'p'))
  hold on
  colour = bone(3*NrJobs);
  colour = colour((NrJobs+1):2*NrJobs,:);
  set(gca,'Color',[1 1 1]/2);
end

[~,jobsize] = sort(sum(p,2));
colour(jobsize,:) = colour;
jobsize(jobsize) = NrJobs:-1:1;
DM = (0.25 + (jobsize/NrJobs)/5)*ones(1,NrMachines);


for job = 1:NrJobs
  rand('seed',job);
  for a = 1:NrMachines
    MAC = sigma(job,a);
    StartPro = X(job,MAC);
    EndPro = X(job,MAC)+p(job,MAC);
    MakeSpan = max(MakeSpan, EndPro);
    dM = DM(job,MAC);
    
    if any(all(fixedjobmac==ones(length(fixedjobmac),1)*[job MAC],2)) % check if a fixed job
      patch([StartPro EndPro EndPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM],colour(job,:),'EdgeColor',[1 1 1]);
    end
    if ~any(all(fixedjobmac==ones(length(fixedjobmac),1)*[job MAC],2)) % check if a fixed job
      if (job == jobdispatched)
        patch([StartPro EndPro EndPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM],'g','EdgeColor',[1 1 1]);
      end
    end
    
    if strcmp(pType(1),'t'),
      plot([StartPro EndPro EndPro StartPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM MAC-dM],'w:');
      h = text(mean([StartPro EndPro]),MAC,sprintf('%d',job));
      if any(all(fixedjobmac==ones(length(fixedjobmac),1)*[job MAC],2)) % check if a fixed job
        set(h,'fontsize',6,'HorizontalAlignment','center','color',[0.9 0.9 0.9]);
      else
        set(h,'fontsize',6,'HorizontalAlignment','center');
      end
    elseif strcmp(pType(1),'p'),
      patch([StartPro EndPro EndPro StartPro],[MAC-dM MAC-dM MAC+dM MAC+dM],colour(job,:),'EdgeColor',[1 1 1]);
    else
    end
  end
end
if (strcmp(pType(1),'t') || strcmp(pType(1),'p'))
  title(sprintf('Job %d dispatched (makespan=%4.2f)',jobdispatched,MakeSpan));
  plot([MakeSpan MakeSpan],[0 NrMachines+1],'k--')
  xlabel('Time');
  ylabel('Machine');
  set(gca,'Ylim',[0 NrMachines+1],'YTick',1:NrMachines);
end

rand('seed',seed); % reset the seed to original state