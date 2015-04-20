function [DAT,XTIME,orgmodel,result] = generate_data(p,sigma,track,print,weights)
% GENERATE_DATA
% example usage:
% probs  = getproblem('../rawData/j.rnd.10x10.train.txt');
% [DAT,XTIME,OPTMODEL] = generate_data(probs(1).p,probs(1).sigma)
%
% see also jssp_gurobi_model, jsp_data.c and gurobi
addpath ../opt
if nargin<3, track='OPT'; end
if nargin<4, print=false; end
if nargin<5, weights=[]; end

%% starts empty
DAT = []; 
XTIME = [];

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

% Now extract the heuristic slot times:
trueOptMakespan = jsp_data(p,sigma,x,n*m,[],ones(1,n*m));

if ((trueOptMakespan-result.objval) > 0.01)
    error('Heuristic sequencing does not give the same result as Gurobi');
end

%%
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
[heuristicMakespan,usedXtime] = jsp_data(p,sigma,x,n*m,weights,useOptimal);

%%
% use these heuristic start times as the intital solution for Gurobi!
model.start = result.x; % copy the Gurobi solution
model.start(1:n*m) = usedXtime(:); % then use the heuristic time slots

% Copy the original model to memory
orgmodel = model;

%% now lets look at an optimal trajectory up to some dispatch step
for dispatchstep = 1:n*m-1, 
    % one step from the end so at least we have two decisions to be made
    if(print), disp(sprintf('step %d',dispatchstep)); end 
        
    %% reset the model to the initial state
    model = orgmodel;
    
    [makespan_partial,xtime_partial,trajectory,lookahead,features] = jsp_data(p,sigma,usedXtime,dispatchstep,weights,useOptimal);
    
    % start by adding the constraints based on the trajectory, I suppose this could be done incrementally:
    A = sparse(dispatchstep,size(model.A,2));
    rhs = round(trajectory(:,3));
    index = trajectory(:,4);
    A((1:dispatchstep)'+(dispatchstep*(index-1))) = 1;
    
    stepconst = size(A,1);
    numconstr = size(model.A,1);
    sense = char(ones(1,dispatchstep)*'=');
    
    model.A((numconstr+1):(numconstr+stepconst),1:n*m) = sparse(A(1:stepconst,1:n*m));
    model.rhs((numconstr+1):(numconstr+stepconst)) = rhs(1:stepconst);
    model.sense((numconstr+1):(numconstr+stepconst)) = sense(1:stepconst);
        
   
    %% now force the different possible dispatches
    for j=1:n
        if (lookahead(j,1) == 0) % end of possible lookaheads
            break;
        end
        model.A(end,:) = zeros(1,size(model.A,2)); % clean constraints
        model.A(end,lookahead(j,4)) = 1;
        model.rhs(end) = round(lookahead(j,3));
        
        % Additional information found solving the LP version:
        lpmodel = model;
        lpmodel.vtype = repmat('C',1,length(model.vtype));
        look(j).lpresult = gurobi(lpmodel, params);
        
        look(j).result = gurobi(model, params);
        if ~strcmp(look(j).result.status,'OPTIMAL'), warning('timeout for lookahead'); end
        
        subx = look(j).result.x(1:n*m);
        look(j).subx = reshape(subx,n,m);
        [makespan,look(j).subx] = jsp_data(p,sigma,look(j).subx,n*m,weights,useOptimal);
        rho = round(makespan-trueOptMakespan) / trueOptMakespan * 100; 
        followed = lookahead(j,1)==features(j,1);
        DAT = [DAT;...
            [dispatchstep makespan lookahead(j,1) features(j,2:end) followed rho ...
            look(j).lpresult.objval look(j).lpresult.itercount ...
            look(j).result.itercount look(j).result.runtime look(j).result.nodecount] ...
            ];
        XTIME = [XTIME look(j).subx(:)];
        
        %if followed
        %   disp([dispatchstep j])
        %end
        
        %if followed & (abs(makespan - heuristicMakespan) > 0.01) % numerical precision is an issue
        %    [makespan heuristicMakespan trueOptMakespan look(j).result.objval]            
        %    save debug
        %    error('Gurobi is not resulting the same makespan as the heuristic constructor');
        %end
    end
    %%
end

