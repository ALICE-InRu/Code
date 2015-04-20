%   FIND FEATURES FOR A JOB GIVEN A PARTIAL JSSP SCHEDULE
%   phi = getFeatures(job,jssp)
%
%   input:  param job, features to inspect for this job
%           param jssp, struct with variables used in jsp_CH.m
%
%   output: var phi, features as described in Table 3.1
% 
%   dependant files: jsp_ch.m
function phi = getFeatures(job,runVar)

numFeatures=13; phi=NaN.*ones(numFeatures,1);

[numJobs,numMacs]=size(runVar.p);
maccount=runVar.maccount;
jobcount=runVar.jobcount;

mac = runVar.sigma(job,maccount(job));

wrm=zeros(1,numJobs);
for j=1:numJobs
  maccount(j);
  wrm(j)=sum(runVar.p(j,runVar.sigma(j,maccount(j)+1:numMacs)));
end
wrm(job)=wrm(job)+runVar.p(job,mac); % in order to discover MWR and LWR dispatching rules

% job-related
phi(1) = runVar.p(job,mac);     % processing time
phi(2) = runVar.xTime(job,mac); % start time
phi(3) = phi(2)+phi(1);         % end time, i.e., time job will be released, release_job(job);
phi(6) = wrm(job);              % work remaining for job
phi(13)= sum(runVar.p(job,:));  % total processing time for job
phi(11)= runVar.wait;           % time job had to wait from previous assignment

% mac-related
phi(4) = runVar.macsfree(mac);% when machine will be free, i.e., release_mac(mac);

% schedule-related
phi(5) = max(runVar.macsfree);% current makespan
phi(7) = max(wrm);            % most work remaining 

% slacks for schedule
slacks=zeros(numMacs,numJobs); 
for m=1:numMacs
  if jobcount(m)>=1
    slacks(m,1)=runVar.sTime(m,1);
  end
  for j=2:jobcount(m)
    slacks(m,j)=runVar.sTime(m,j)-runVar.eTime(m,j-1);
  end  
end
sumslacks=sum(slacks,2);
phi(8) = sumslacks(mac);        % total slacks on mac
phi(9) = sum(sumslacks);        % total slacks on all macs
phi(10)= phi(9)/sum(jobcount);  % total slacks divided by #op.
phi(12)=runVar.slotcreated;

%% old stuff


% phi(8) = sumslacks + (starttime - runVar.sTime(mac,slot)); % add new slack
% 
% if (slotsize < phi(5))  % new slot is finite and reduced then by time
%   phi(8) = sumslacks - time;  % slack reduced by time
%   phi(9) = runVar.eTime(mac,slot) - (starttime + time);
% else
%   phi(9) = 0.0;
% end
% 
% for j=1:jobcountmac
%   if (j == slot)
%     phi(9) = phi(9) + (starttime - runVar.sTime(mac,j));
%   elseif (runVar.eTime(mac,j) < phi(5))
%     phi(9) = phi(9) + (runVar.eTime(mac,j) - runVar.sTime(mac,j));
%   end
% end
% phi(10) = phi(9) / (time + operations);
% phi(11) = starttime - jobtime(job); % how long the job must wait
% phi(12) = starttime - runVar.sTime(mac,slot); % does the assignment create a new slot?

end

