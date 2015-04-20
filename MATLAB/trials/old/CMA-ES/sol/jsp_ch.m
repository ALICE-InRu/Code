%   CONSTRUCTION HEURISTIC FOR JSSP
%   [MakeSpan,seq,jssp]=jsp_ch(seq,p,sigma,jssp,slottype)
%
%   input:  param seq, only a sequence of dispatched jobs
%           param p, processing times
%           param sigma, premutation of machines
%           param slottype, first (default) vs. smallest slot chosen
%           ---> optional param
%           param jssp keeps running variables from the code, can be
%                 used to speed up computations if using same initial seq.
%                 from previous runs
%
%   output: var Makespan, current makespan for given seq.
%           var jssp, struct with variables that describe the partial
%                  schedule, e.g., fundamental in getFeatures.m
%
function [MakeSpan,jssp] = jsp_ch(seq,p,sigma,jssp,slottype)

finalStep=length(seq);

if nargin<5
  slottype='first'; % default construction heuristic is to allocate to the first slot available
end

[numJobs,numMacs]=size(p);

%% Initialization
if nargin<4 | isempty(jssp)
  jssp.p=p;
  jssp.sigma=sigma;
  
  jssp.macsfree = zeros(1,numMacs);  % current makespan for machine
  jssp.jobcount = zeros(1,numMacs); % number of jobs already dispatched
  
  jssp.sTime = Inf.*ones(numMacs,numJobs); % starting times for jobs (not in sigma order)
  jssp.eTime = Inf.*ones(numMacs,numJobs); % end times for jobs (not in sigma order)
  
  % For job-oriented view
  jssp.jobsfree = zeros(1,numJobs);  % release time for perm.constr.
  jssp.maccount = zeros(1,numJobs); % number of macs already traversed
  
  jssp.xTime = NaN.*ones(numJobs,numMacs); % starting times for macs (in sigma order)
  % finishing times for macs is easily computed by adding the correct p value
  
  firstStep=1;
else
  firstStep=sum(jssp.maccount)+1;
end
%% Dispatching begins
for k = firstStep:finalStep
  job = seq(k); % the job to be scheduled
  jssp.maccount(job)=jssp.maccount(job)+1; % update its number of tasks completed
  mac = sigma(job,jssp.maccount(job)); % get the machine ID for this job
  jssp.jobcount(mac)=jssp.jobcount(mac)+1; % update the number of jobs dispatched
  time = p(job,mac); % the processing time for (job on mac)
  slotsizes=zeros(1,numJobs);
  % Find new slot time:
  if jssp.jobcount(mac)==1 % never been assigned before, no need to check for slotsizes
    starttime=jssp.jobsfree(job); % release time from previous mac.
    jssp.sTime(mac,1)=starttime;
    jssp.eTime(mac,1)=starttime+time;
    slotsizes(1)=Inf;slot=1;
  else % possibility of slots
    % first slot:
    slotsizes(1)=max(jssp.sTime(mac,1)-jssp.jobsfree(job),0);
    % rest of slots:
    for j_prime=2:jssp.jobcount(mac)
      slotsizes(j_prime)=jssp.sTime(mac,j_prime)-max(jssp.eTime(mac,j_prime-1),jssp.jobsfree(job));
    end
    I = find(slotsizes>=time);
    
    if strcmpi(slottype,'first')
      id_slot=1; % pick the first slot
    else % pick slot corresponding to smallest slotsize
      [dummy,id_slot]=min(slotsizes(I));
      % slotsize -- getur gefið okkur tilffinalStepi þar sem opt. finnst ekki!
      % sbr.% profanir/fault.fig og vs. profanir/opt.fig
    end
    slot=I(id_slot); 
    
    % Update
    if slot>1
      starttime=max(jssp.eTime(mac,slot-1),jssp.jobsfree(job));
    else
      starttime=max(jssp.jobsfree(job));
    end
    
    jssp.sTime(mac,1:slot-1)=jssp.sTime(mac,1:slot-1);
    jssp.sTime(mac,slot+1:jssp.jobcount(mac))=jssp.sTime(mac,slot:jssp.jobcount(mac)-1);
    jssp.sTime(mac,slot)=starttime;
    if sort(jssp.sTime(mac,:),'ascend')~=jssp.sTime(mac,:), warning(['ath' num2str(k) ' of' num2str(finalStep)]); end
    
    jssp.eTime(mac,1:slot-1)=jssp.eTime(mac,1:slot-1);
    jssp.eTime(mac,slot+1:jssp.jobcount(mac))=jssp.eTime(mac,slot:jssp.jobcount(mac)-1);
    jssp.eTime(mac,slot)=starttime+time;
    if sort(jssp.eTime(mac,:),'ascend')~=jssp.eTime(mac,:), warning(['ath' num2str(k) ' of' num2str(finalStep)]); end
    
    % legal = jsp_errorcheck(jssp); disp(k)
    % if legal==0, error('ath'), end
  end
  
  if slot<jssp.jobcount(mac) % job inserted into the schedule, i.e. used a slot instead of being set at the back
    jssp.slotcreated=slotsizes(slot)-time;
  else
    jssp.slotcreated=0;
  end

  jssp.slotsizes=slotsizes;               % info needed for getfeatures.m
  jssp.wait=starttime-jssp.jobsfree(job); % info needed for getfeatures.m
  
  jssp.xTime(job,mac)= starttime;
  jssp.jobsfree(job) = starttime + time; % the time this job will be released
  jssp.macsfree(mac) = max(jssp.eTime(mac,1:jssp.jobcount(mac))'); % the new time this machine will be free again
  
  % update outputs
  jssp.seq_jobs(k)=job;
  jssp.seq_macs(k)=mac;
  jssp.seq_start(k)=starttime;

end

%%
MakeSpan = max(jssp.macsfree);
end


% function legal = jsp_errorcheck(jssp)
% p=jssp.p;
% sigma=jssp.sigma;
% % Permutation constr.
% for job=1:numJobs
%   for mac=1:numMacs-1
%     if ~isnan(jssp.xTime(job,sigma(job,mac+1)))
%       if jssp.xTime(job,sigma(job,mac+1))>=jssp.xTime(job,sigma(job,mac))+p(job,sigma(job,mac))
%         legal=true;
%       else
%         fprintf('job %d á vél %d\n',job,sigma(job,mac))
%         jssp.xTime(job,sigma(job,mac+1))
%         jssp.xTime(job,sigma(job,mac))+p(job,sigma(job,mac))
%         legal=false; return
%       end
%     end
%   end
% end
%
%
% % One job at a time
% for mac=1:numMacs
%   for job=2:numJobs
%     if ~isinf(jssp.eTime(mac,job)) & ~isinf(jssp.sTime(mac,job))
%       if jssp.eTime(mac,job)>jssp.sTime(mac,job)
%         legal=true;
%       else
%         legal=false; return
%       end
%       if jssp.sTime(mac,job)>=jssp.eTime(mac,job-1)
%         % ok
%       else
%         jssp.eTime(mac,job-1)
%         jssp.sTime(mac,job)
%         fprintf('Vél %d: verk %d vs. verk %d\n',mac,job,job+1)
%         warning('ath, verið að þjófstarta')
%         legal=false; return
%       end
%
%     end
%   end
% end
%
% end
