function [DAT,XTIME,orgmodel,result] = retrace_generate_data(p,sigma,prevRun,opt)
% GENERATE_DATA
% example usage:
% probs  = getproblem('../rawData/j.rnd.10x10.train.txt');
% [DAT,XTIME,OPTMODEL] = generate_data(probs(1).p,probs(1).sigma)
%
% see also jssp_gurobi_model, jsp_data.c and gurobi
addpath ../common/
%% starts empty
DAT = []; 
row=0;

%% read from previous run
XTIME = prevRun.xTime;
result=prevRun.result;
orgmodel=prevRun.model;

%% now in what sequence are the jobs scheduled on a machine? 
% get their start times:
[n,m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

% Now extract the heuristic slot times:
[makespan,xtime] = jsp_data(p,sigma,x,n*m);

%% make sure it is in fact optimal! 
if nargin==4 & strcmp(opt.solved,'opt')
    makespan_2=opt.makespan;
else
    addpath ../opt/
    [makespan_2,xtime_2,solved_2,result_2] = gurobiOpt(p,sigma);        
end
if(makespan_2 ~= makespan) warning('Optimal makespan does not match gurobiOpt'); return; end

%% now lets look at an optimal trajectory up to some dispatch step
for dispatchstep = 1:n*m-1, % one steps from the end so at least we have two decisions to be made
    
    %% reset the model to the initial state    
    [makespan_partial,xtime_partial,trajectory,lookahead,features] = jsp_data(p,sigma,xtime,dispatchstep);
    
    %% now force the different possible dispatches
    for j=1:n
        if (lookahead(j,1) == 0) % end of possible lookaheads
            break;
        end
        
        row=row+1;
        if(row>size(prevRun.dat,1))
           warning('Breaking, not enough rows for dispatch');
           DAT=[];
           return;
        end
        prevRow=prevRun.dat(row,:);
        % [dispatchstep makespan features(j,:) ...
        % look(j).lpresult.objval look(j).lpresult.itercount ...
        % look(j).result.itercount look(j).result.runtime look(j).result.nodecount] ...
        % ];
        makespan = prevRow(2);
        
        rho = round(makespan-result.objval) / result.objval * 100; 
        followed = lookahead(j,1)==features(j,1);        
        
        DAT = [DAT;...
            [dispatchstep makespan lookahead(j,1) features(j,2:end) followed rho ...
            prevRow(end-4:end)] ...
            ];
                
    end
    %%
end
