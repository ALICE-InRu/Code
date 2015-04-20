%   APPLY SUPERVISED LEARNING LINEAR PRIORITY DISPATCH RULES (SLLPDR)
%   [makespan ratio FEATURES]=SLLPDR(model,rawData)
%  
%   input:  param model, struct with fields X1, X2 and Y12
%           param rawData, struct with fields p and sigma
%  
%   output: var makespan, makespan using given model
%           var ratio, deviation from known optimum
%           var FEATURES, struct with results from getFeatures.m 
%               (used for studies in ch.5)
% 
%   dependant files: getFeatures.m jsp_ch.m
%          -- LIBSVM or LIBLINEAR depending on input model
function [makespan ratio FEATURES]=SLLPDR(model,rawData,svmparam)
%% Initialization
% Dimensions and number of instances
[numInstances]=length(rawData);
ratio=NaN.*zeros(1,numInstances);

[numJobs,numMacs]=size(rawData(1).p); % Dimensions of JSSP
dim2=numJobs*numMacs; % Number of sequences that have to be made

FEATURES(dim2).Xfeatures=[]; 
FEATURES(dim2).FTMP=[]; 
numFeatures=13;

if isfield(model,'alpha')
  addpath svm/
  type='libsvm';  
elseif isfield(model,{'w','b'})
  type='liblinear'; 
else
  type=lower(model);
  error('Note, model is not of the right form.')
end

%% Data instance
for II = 1:numInstances, 
  % progress bar 
  if rem(II,100)==0, fprintf('Progress bar:...... %d of %d iterations\n',II,numInstances); end
  
  %% Initialization for problem instance
  p=rawData(II).p;
  sigma=rawData(II).sigma;
    
  [numJobs,numMacs]=size(p);    
  
  % partial schedule 
  jssp.p=p;
  jssp.sigma=sigma;
  
  % mac-oriented
  jssp.macsfree = zeros(1,numMacs); % current makespan for machine
  jssp.jobcount = zeros(1,numMacs); % number of jobs already dispatched
  jssp.sTime = Inf.*ones(numMacs,numJobs); % starting times for jobs (not in sigma order)
  jssp.eTime = Inf.*ones(numMacs,numJobs); % end times for jobs (not in sigma order)
  
  % job-oriented
  jssp.jobsfree = zeros(1,numJobs); % release time for perm.constr.
  jssp.maccount = zeros(1,numJobs); % number of macs already traversed
  jssp.xTime = NaN.*ones(numJobs,numMacs); % starting times for macs (in sigma order)
  
  % sequence of dispatches
  seq=[]; % jobs that have been dispatched
  workremaining=sum(p,2);
  
  %% Move corresponding to the highest feature-value is chosen at each timestep
  for step = 1:dim2, 
    readylist=find(jssp.maccount<numMacs);
    Ftmp = zeros(size(readylist)); % priority 
    Xfeatures = zeros(numJobs,numFeatures);
    numCheck=length(readylist);
    
    %% Compute feature value [makespan ratio]=SLLPDR(model,rawData)s for each unfinished jobs
    for i=1:numCheck
      j=readylist(i);
      % Add j to set of dispatched jobs:
      jobs_try=[seq j];   
      [dummy,jssp_try] = jsp_ch(jobs_try,p,sigma,jssp); % one-step lookahead
      Xfeatures(j,:) = getFeatures(j,jssp_try);     % find its features
      
      % Apply method - liblinear, libsvm or simple DR
      if strncmp(type,'lib',3) % LIBLINEAR LIBSVM   
      % Xfeatures(i,:) = svm_scale(Xfeatures(j,:)', model(step).scalefac,model(step).offset);     
        if strcmp(type,'liblinear')
          Ftmp(i) = model(step).w*Xfeatures(j,:)'+model(step).b;
        elseif strcmp(type,'libsvm')          
          if numCheck > 1, 
            Xfeatures(j,:) = svm_scale(Xfeatures(j,:)',model(step).scalefac,model(step).offset);     
            Ftmp(i) = svm_predict(Xfeatures(j,:)', model(step).X1sc, model(step).X2sc, model(step).alpha, model(step).Y12',svmparam); 
          end
        end
      else % dispatching rule        
        eval(['[dummy,Ftmp]=' type '(workremaining,readylist,p,sigma,MacCounter);'])        
      end
      
    end    
    [dummy,id] = max(Ftmp); j_use=readylist(id); % choose the one with the highest priority
   
    %% add dispatch to sequence, and update partial schedule
    seq=[seq j_use];
    [dummy,jssp] = jsp_ch(seq,p,sigma,jssp); 
        
    % features chosen 
    tmp=zeros(1,numJobs); tmp(readylist)=Ftmp;
    FEATURES(step).FTMP=[FEATURES(step).FTMP;tmp]; clear tmp
    FEATURES(step).Xfeatures=[FEATURES(step).Xfeatures; Xfeatures(j_use,:)];

  end
  makespan(II)=max(jssp.macsfree); % final "current" makespan
  if isfield(rawData,'makespan')
    ratio(II)=(makespan(II)-rawData(II).makespan)/rawData(II).makespan*100;
  end
end

end % end of main function 

