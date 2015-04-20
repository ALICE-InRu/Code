function [DAT,XTIME,orgmodel,result] = generate_data(p,sigma)
% GENERATE_DATA
% example usage:
% probs  = getproblem('../Scheduling/rawData/jrnd_10x10_Train.txt');
% [DAT,XTIME,OPTMODEL] = generate_data(probs(1).p,probs(1).sigma)
%
% see also jssp_gurobi_model, jsp_data.c and gurobi

DAT = []; % starts empty
XTIME = [];

% create a jssp model that Gurobi can solve
model = jssp_gurobi_model(p,sigma);

% create optimization parameter structure
clear params
params.outputflag = 0;
params.Threads = 4;
%params.TimeLimit = 500; % seconds?! % if you can to use a timeout
% now optimize using Gurobi:
result = gurobi(model, params)
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
[makespan,xtime] = jsp_data(p,sigma,x,n*m);

if ((makespan-result.objval) > 0.01)
  error('Heuristic sequencing does not give the same result as Gurobi');
end

% use these heuristic start times as the intital solution for Gurobi!
model.start = result.x; % copy the Guribi solution
model.start(1:n*m) = xtime(:); % then use the heuristic time slots 

% Copy the original model to memory
orgmodel = model;

% now lets look at an optimal trajectory up to some dispatch step
for dispatchstep = 1:n*m-1, dispatchstep % one steps from the end so at least we have two decisions to be made

% reset the model to the initial state
  model = orgmodel;
  
  [makespan_partial,xtime_partial,trajectory,lookahead,features] = jsp_data(p,sigma,xtime,dispatchstep);

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

  % now force the different possible dispatches
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
    %%%
    
    look(j).result = gurobi(model, params);
    if ~strcmp(look(j).result.status,'OPTIMAL'), warning('timeout for lookahead'); end
    
    subx = look(j).result.x(1:n*m);
    look(j).subx = reshape(subx,n,m);
    [makespan,look(j).subx] = jsp_data(p,sigma,look(j).subx,n*m);
    DAT = [DAT;...
      [dispatchstep makespan features(j,:) ...
      look(j).lpresult.objval look(j).lpresult.itercount ...
      look(j).result.itercount look(j).result.runtime look(j).result.nodecount] ...
      ];
    XTIME = [XTIME look(j).subx(:)];
    if (abs(makespan - look(j).result.objval) > 0.01) % numerical precision is an issue
      [makespan look(j).result.objval]
      save debug
      error('Gurobi is not resulting the same makespan as the heuristic constructor');
    end
  end
end