clear all; clc;
distr='j.rnd';
dim='6x5';
track='SPT';
addpath ../trainingData/
addpath ../opt/
problems  = getproblem(sprintf('../../rawData/%s.%s.train.txt',distr,dim));
fname=sprintf('%s.%s.train.%s.hi.mat',distr,dim,track);
pname=sprintf('%s.%s.train.%s.tpr.mat',distr,dim,track);
OPT=load(sprintf('../opt/opt.%s.%s.train.mat',distr,dim));
% Get weights for features w.r.t. trajectory to follow
weights=getWeight(distr,dim,previousTrack(track));
PID=1;
p=problems(PID).p;
sigma=problems(PID).sigma;

% create a jssp model that Gurobi can solve
model = jssp_gurobi_model(p,sigma);

% create optimization parameter structure
clear params
params.outputflag = 0;
params.Threads = 4;
%params.TimeLimit = 500; % seconds?! % if you can to use a timeout
% now optimize using Gurobi:
result = gurobi(model, params);
if ~strcmp(result.status,'OPTIMAL')
    warning('optimal solution not found!');
    return;
end

% now in what sequence are the jobs scheduled on a machine?
% get their start times:
[n,m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

if strcmpi(track,'OPT') % Optimal trajectory
    useOptimal=ones(1,n*m);
elseif length(track)>3    
    if strcmpi(track(4),'S') % Supervised imitation learning
        prob=0.5^str2num(track(3));        
        for dispatchstep=1:n*m
            useOptimal(dispatchstep)=rand() < prob;
        end        
    else 
        useOptimal=zeros(1,n*m); % Unsupervised imitation learning
    end
else
    useOptimal=zeros(1,n*m); % always follow simple priority dispatching rule
end
%%
weights
useOptimal

%%
mex jsp_data.c
trueOptMakespan = jsp_data(p,sigma,x,n*m,[],ones(1,n*m)) %% 497
if(trueOptMakespan ~= 497)
    error('trueOptMakespan  is not correct')
end

if(trueOptMakespan ~= 497)
    error('trueOptMakespan  is not correct')
end
save debug-me
%% ætti að vera 622 fyrir SPT
weights=getWeight(distr,dim,'SPT');
heuristicMakespan = jsp_data(p,sigma,x,n*m,weights,useOptimal);
if(heuristicMakespan  ~= 622)
    for step=1:n*m 
    makespan_partial=jsp_data(p,sigma,x,step,weights,useOptimal);
    disp([step-1 makespan_partial]);
    end
    error('SPT is not correct - ATH klikkar í step 27')
end

%% ætti að vera 721 fyrir LPT
weights=getWeight(distr,dim,'LPT');
heuristicMakespan = jsp_data(p,sigma,x,n*m,weights,useOptimal);
if(heuristicMakespan  ~= 721)
    for step=1:n*m 
    makespan_partial=jsp_data(p,sigma,x,step,weights,useOptimal);
    disp([step-1 makespan_partial]);
    end
    error('LPT is not correct - ATH klikkar í step 27')
end
%% ætti að vera 656 fyrir MWR
weights=getWeight(distr,dim,'MWR');
heuristicMakespan = jsp_data(p,sigma,x,n*m,weights,useOptimal);
if(heuristicMakespan  ~= 656)
    for step=1:n*m 
    makespan_partial=jsp_data(p,sigma,x,step,weights,useOptimal);
    disp([step-1 makespan_partial]);
    end
    error('MWR is not correct')
end

%% ætti að vera 625 fyrir LWR
weights=getWeight(distr,dim,'LWR');
heuristicMakespan = jsp_data(p,sigma,x,n*m,weights,useOptimal);
if(heuristicMakespan  ~= 625)
    for step=1:n*m 
    makespan_partial=jsp_data(p,sigma,x,step,weights,useOptimal);
    disp([step-1 makespan_partial]);
    end
    error('LWR is not correct - ATH klikkar í step 17: 1.0.152->333')
end
