function [makespan,xtime,solved,result] = gurobiOpt(p,sigma)

%% create a jssp model that Gurobi can solve
model = jssp_gurobi_model(p,sigma);

%% create optimization parameter structure
params.outputflag = 0;
params.Threads = 4;
param.IterationLimit =1e7;
param.Display=1;
param.DisplayInterval=10; % seconds
%params.TimeLimit = 500; % seconds?! % if you can to use a timeout

%% now optimize using Gurobi:
result = gurobi(model, params);

if ~strcmp(result.status,'OPTIMAL')
    solved='bks';
else
    solved='opt';
end

%% now in what sequence are the jobs scheduled on a machine?
% get their start times:
[n,m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

% Now extract the heuristic slot times:
[makespan,xtime] = jsp_data(p,sigma,x,n*m);

% if ((makespan-result.objval) > 0.01)
%     error('Heuristic sequencing does not give the same result as Gurobi');
% end


end

