%cd ~/Work/scheduling/jsp/mlb/cmaes_run/sol 
%! scp sol.raunvis.hi.is:jsp-cma/*cmarun.mat .

clear all, clc,
types={'jrnd','jrndn','frnd','frndn','fjc','fmc','fmxc'}; 

fid = fopen('CMAratiorun.6x5.csv','w');
fprintf(fid, sprintf('trainingdata,generation,fitness,pass\n'));
fidw = fopen('CMAratioweight.6x5.csv','w');
fprintf(fidw, sprintf('trainingdata,generation,weight,featureID,feature\n'));
features={'proc','startTime','endTime','macFree','makespan','wrmJob','mwrmJob','slots','slotsTotal','slotsTotalPOP','wait','slotsCreated','totalProc'};

for itNow=1:length(types)
  
  usenow=[types{itNow} '-cmarun'];
  load(usenow);
  
  %% ------------- Final Message and Plotting Figures --------------------
  disp([usenow(1) 'sp ' usenow(2:end-7) ' #' num2str(counteval) ': ' num2str(arfitness(1))]);
  xmin = arx(:, arindex(1)); % Return best point of last iteration.
  % Notice that xmean is expected to be even
  % better.
  close all;
  
%   figure(1); subplot(1,2,1), hold off; semilogy(abs(out.dat(:,1:2))); hold on;  % abs for negative fitness
%   semilogy(out.dat(:,1) - min(out.dat(:,1)), 'k-');  % difference to best ever fitness, zero is not displayed  
%   legend({'fitness','sigma','difference'},'location','best'); grid on; xlabel('iteration');
%   title(usenow)
%   
%   figure(1), subplot(1,2,2), semilogy(abs(out.dat(:,3:16)));
%   ylabel('sqrt(eigenvalues)'); grid on; xlabel('iteration');
%   %legend({'w_1' 'w_2' 'w_3' 'w_4' 'w_5' 'w_6' 'w_7' 'w_8' 'w_9' 'w_{10}' 'w_{11}' 'w_{12}' 'w_{13}' 'b' },'location','NorthEastOutside')
  
  for II=1:length(out.dat)
    fprintf(fid, sprintf('%s.%s,%d,%f,%f\n',types{itNow}(1),types{itNow}(2:end),II,out.dat(II,1:2)));
    for III=1:numFeatures
      fprintf(fidw, sprintf('%s.%s,%d,%f,%d,%s\n',types{itNow}(1),types{itNow}(2:end),II,out.datx(II,III),III,features{III}));      
    end    
  end
%     
%   figure(2); hold off; plot(out.datx);
%   title([ usenow '   Distribution Mean']); grid on; xlabel('iteration')
%   legend({'w_1' 'w_2' 'w_3' 'w_4' 'w_5' 'w_6' 'w_7' 'w_8' 'w_9' 'w_{10}' 'w_{11}' 'w_{12}' 'w_{13}' 'b' },'location','NorthEastOutside')
%   
  esWeights=xmin;
  
  esWeights=esWeights/norm(esWeights);
  save([usenow '-esweights'],'esWeights') 
end

fclose(fid)
fclose(fidw)