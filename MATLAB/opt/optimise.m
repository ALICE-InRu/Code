function optimise(distribution,dimension,set,maxPID)
if(nargin<4) maxPID=500; end
if(nargin<3) set='test'; end
if(nargin<2) dimension='10x10'; end

problems  = getproblem(sprintf('../../rawData/%s.%s.%s.txt',distribution,dimension,set));
fname=sprintf('opt.%s.%s.%s.mat',distribution,dimension,set);

if exist(fname,'file')
    load(fname,'DAT');
    start=length(DAT)+1+1;
else
    start=1;
end

if strcmp(set,'test')
    translate=5000;
else
    translate=0;
end

tname = sprintf('../trainingData/%s.%s.%s.OPT.mat',distribution,dimension,set);

if(exist(tname,'file'))
    canRead=1;
    tr=load(tname);
else
    canRead=0;
end

for PID=start:min(maxPID,length(problems)-translate),
    disp(sprintf('%s.%s #%d',distribution,dimension,PID))
    if canRead 
        if PID<=length(tr.DAT)
            if(~isempty(tr.DAT(PID).result))
                [DAT(PID).makespan,DAT(PID).xtime,DAT(PID).solved,DAT(PID).result] = read(tr.DAT(PID).result,problems(PID+translate).p,problems(PID+translate).sigma);
            else
                disp(sprintf('missing %d',PID))                
            end
        else
            canRead=0;
        end
    end    
    if(~canRead)        
        [DAT(PID).makespan,DAT(PID).xtime,DAT(PID).solved,DAT(PID).result] = gurobiOpt(problems(PID+translate).p,problems(PID+translate).sigma);
        save(fname,'DAT')
    end    
end
save(fname,'DAT')

%% check for missing values
for PID=1:min(maxPID,length(problems)-translate),
    if isempty(DAT(PID).result), disp(sprintf('%s.%s #%d',distribution,dimension,PID))
        [DAT(PID).makespan,DAT(PID).xtime,DAT(PID).solved,DAT(PID).result] = gurobiOpt(problems(PID+translate).p,problems(PID+translate).sigma);
        save(fname,'DAT')
    end
end

%%
save(fname)
end

function [makespan,xtime,solved,result] = read(result,p,sigma)

if ~strcmp(result.status,'OPTIMAL')
    solved='bks';
else
    solved='opt';
end

% get their start times:
[n,m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

% Now extract the heuristic slot times:
[makespan,xtime] = jsp_data(p,sigma,x,n*m);


if ((makespan-result.objval) > 0.01)
    error('Heuristic sequencing does not give the same result as Gurobi');
end

end

