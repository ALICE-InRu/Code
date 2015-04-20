clear all, close all
%% DATA
problems  = getproblem('../rawData/j.rnd.10x10.train.txt');
p = problems(1).p; sigma = problems(1).sigma;

%% MODEL
model = jssp_gurobi_model(p,sigma)
clear params;
params.outputflag = 0;
params.Threads = 4;
%params.method = 2;
%params.TimeLimit = 10; % seconds?!
result = gurobi(model, params);

%% now in what sequence are the jobs scheduled on a machine?
[n m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

%% Now extract the heurstic slot times:
[makespan,xtime,stime,etime] = jsp_data(p,sigma,x,n*m);

%return

x = xtime;
result.x(1:n*m) = x(:);

%% the order of jobs on machine 1 are:
for i=1:m
  [~,joborder(i,:)] = sort(x(:,i)');
end

%% Draw this schedule:
MakeSpan = ganttch(x, p, sigma,'text')

% now lets look at an optimal trajectory up to some dispatch step
dispatchstep = 50;
[makespan_partial,xtime_partial,trajectory,lookahead,features] = jsp_data(p,sigma,x,dispatchstep);

% start by adding the constraints based on the trajectory
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
model.start = result.x;
%% now force the different possible dispatches
DATA = [];
for j=1:n
  if (lookahead(j,1) == 0) % end of possible lookaheads
    break;
  end
  model.A(end,:) = zeros(1,size(model.A,2)); % clean constraints
  model.A(end,lookahead(j,4)) = 1;
  model.rhs(end) = round(lookahead(j,3));
  lookahead(j,:)
  look(j).result = gurobi(model, params)
  subx = look(j).result.x(1:n*m);
  look(j).subx = reshape(subx,n,m);
  [makespan,look(j).subx] = jsp_data(p,sigma,look(j).subx,n*m);
  DATA = [DATA;[look(j).result.objval features(j,:)]];
  if (abs(makespan - look(j).result.objval) > 0.0001) % numerical precision is an issue
    warning('Gurobi is not resulting the same makespan as the heuristic constructor');
    [makespan look(j).result.objval]
  end
end
disp(result)
clf
%set(gcf, 'inverthardcopy', 'off')
%fig_size = [50 50 800 600];
%set(gcf,'Units','pixels','Position',fig_size,'Units','inches')
for i=1:length(look),
  %tag_ganttch((look(i).subx),p,sigma,'text',trajectory(1:end-1,1:2),lookahead(i,1));
  tag_demo_ganttch((look(i).subx),p,sigma,'text',trajectory(1:end-1,1:2),1:n);
  lookahead(i,1:2)
  set(gca,'xlim',[0 ceil(MakeSpan*1.2)]),
  drawnow;
  eval(sprintf('print -depsc demo/demo_%d_%d.eps', dispatchstep, i));
  %M(i) = getframe(gcf,fig_size);
  clf,
end

%% Merge eps files to pdf
eval(sprintf('! gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER  -sOutputFile=demo/demo_%d_merged.pdf demo/demo_%d*.eps\n',dispatchstep,dispatchstep));

