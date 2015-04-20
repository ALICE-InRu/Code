function mat2csv(problem,dim,track)
%%
track=upper(track);
fName=['../../trainingData/trdat.' problem '.' dim '.' track '.MATLAB.hi.csv'];
if(exist(fName, 'file')), disp('File already exists'), return; end
load(sprintf('%s.%s.train.%s.hi.mat',problem,dim,track));
shop=problem(1);
distr=problem(3:end);
%%
%  DAT = [DAT;...
%             [dispatchstep makespan j features(j,2:end) j==features(j,1) rho ...
%             look(j).lpresult.objval look(j).lpresult.itercount ...
%             look(j).result.itercount look(j).result.runtime look(j).result.nodecount] ...
%             ];

ncol = size(DAT(1).dat,2);
colStep=1;
colMakespan=2;
colFeatures=colMakespan+(1:15);
colFollowed=ncol-6;
colRho=ncol-5;
%colLPresult_objval=ncol-4;
%colLPresult_itercount=ncol-3;
colResult_itercount=ncol-2;
%colResult_runtime=ncol-1;
%colResult_nodecount=ncol;

%%
featureNames{15}=[];
% phi[k +  0*n] = optjob + 1;  /* The job to be dispatched */
featureNames{1}='job';
colJob=colFeatures(1);
% phi[k +  1*n] = mac + 1;     /* Are jobs on the same machine? */
featureNames{2}='mac';
colMac=colFeatures(2); 
% phi[k +  2*n] = starttime;   /* start time for this job */
featureNames{3}='startTime';
% phi[k +  3*n] = jobtime[j];  /* arrival time for a job, FIFO, AT, C_{i,j-1} in Haupt88 */
featureNames{4}='arrivalTime';
% phi[k +  4*n] = jobworkremaining[j]; /* MWRM, work remaining for this job */
featureNames{5}='wrmJob';
% phi[k +  5*n] = p[j + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
featureNames{6}='proc';
% phi[k +  6*n] = jobcount[j];  /* Greatest/fewest number of jobs remaining assumes number of operation to be the same for all jobs */
featureNames{7}='jobOps';
% phi[k +  7*n] = totalwork[j]; /* the greatest total work */
featureNames{8}='totproc';
% phi[k +  8*n] = starttime - jobtime[j]; /* the waiting time for this job */
featureNames{9}='wait';
% phi[k +  9*n] = (double)(eTime[slot] < (infinity-1)); /* is the job inserted in an available slot, or attached to the end? */
featureNames{10}='slotReduced';
% phi[k + 10*n] = MAX(mactime[mac], starttime + p[j + n * mac]); /* new completion time for the machine */
featureNames{11}='macfree';
% phi[k + 11*n] = MAX(Makespan[0],MAX(mactime[mac], starttime + p[j + n * mac])); /* new global makespan */
featureNames{12}='makespan';
% phi[k + 12*n] = macworkremaining[mac]; /* This would only make sense when comparing different machines, else anyway zero, total Work In Queue WINQ for machine mac */
featureNames{13}='wrmMac';
% phi[k + 13*n] = starttime - sTime[mac + m * slot]; /* size of slot insert space created */
featureNames{14}='slots';
% phi[k + 14*n] = starttime + p[j + n * mac]; /* new completion time for this job */
featureNames{15}='endTime';
header=['Shop,Distribution,Track,PID,Step,ResultingOptMakespan,Optimum,Simplex,Dispatch,Followed,Rho'];
for i=1:length(featureNames)
    header=sprintf('%s,phi.%s',header,featureNames{i});
end
%%
fid = fopen(fName,'w');            %# Open the file
if fid ~= -1
  fprintf(fid,'%s\r\n',header);    %# Print the header
  
  for PID=1:length(DAT), %PID       
      pDAT=DAT(PID).dat;
      for ii=1:size(pDAT,1)
          Step=pDAT(ii,colStep);          
          ResultingOptMakespan=pDAT(ii,colMakespan);
          Optimum=DAT(PID).result.objval;
          Simplex=pDAT(ii,colResult_itercount);
          Dispatch=sprintf('%d.%d.0',pDAT(ii,colJob)-1,pDAT(ii,colMac)-1);
          features=pDAT(ii,colFeatures);          
          Followed=pDAT(ii,colFollowed);          
          Rho=pDAT(ii,colRho);          
          fprintf(fid,'%s,%s,%s,%d,%d,%d,%d,%d,%s,%d,%.4f%s\r\n',shop,distr,track,PID,Step-1,ResultingOptMakespan,Optimum,Simplex,Dispatch,Followed,Rho,sprintf(',%d',features));
      end
  end
  
  fclose(fid);                     %# Close the file
end

