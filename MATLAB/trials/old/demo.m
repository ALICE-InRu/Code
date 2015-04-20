% j.rnd.10x10.test.1,j,rnd,Test,1,10,10,100,873,opt,Gurobi,37310
%TRAIN SET problems from subfolder generator/rnd_10x10 with random machine order (seed=19850712)
%+++++++++
%instance problem.0
%+++++++++
%10 10
clear all, close all
data = [
7 73 2 95 9 72 0 21 5 28 1 11 6 76 8 89 4 59 3 96 
1 69 7 92 8 62 5 68 2 67 6 36 0 43 4 7 9 69 3 45 
8 52 5 26 9 18 3 74 0 67 6 10 2 76 7 41 4 21 1 46 
7 78 0 75 5 64 2 70 9 55 1 19 6 53 8 75 3 67 4 92 
6 29 3 22 9 56 4 8 2 62 5 23 7 93 0 52 1 58 8 10 
2 86 5 72 9 42 6 40 0 58 4 54 7 6 1 16 3 5 8 74 
8 20 3 33 5 52 1 6 0 71 9 59 6 2 2 15 4 89 7 10 
8 37 4 71 9 80 2 89 7 84 6 49 1 40 3 93 5 93 0 60 
2 32 8 71 0 59 6 27 5 28 7 48 9 28 4 70 3 23 1 44 
9 47 5 42 7 63 3 90 2 62 8 19 4 22 0 48 6 14 1 8 
]
%n = 5; m = 5;
%data = ceil(100*rand(n,2*m));
%for i=1:n
%  data(i,1:2:end-1) = randperm(m)-1;
%end
p = data(:,2:2:end);
sigma = data(:,1:2:end)+1;
% perhaps the process times need to be re-ordered?
% for i=1:size(p,1), p(i,:) = p(i,sigma(i,:)); end
%p(:,1) = p(:,1)*2;
%p(1,:) = floor(p(1,:)*1.4);

model = jssp_gurobi_model(p,sigma)
clear params;
params.outputflag = 0;
params.Threads = 4;
%params.method = 2;
%params.TimeLimit = 10; % seconds?!
result = gurobi(model, params);

% now in what sequence are the jobs scheduled on a machine?
[n m] = size(p);
x = result.x(1:n*m);
x = reshape(x,n,m);

% Now extract the heurstic slot times:
[makespan,xtime,stime,etime] = jsp_data(p,sigma,x,n*m);

%return

x = xtime;
result.x(1:n*m) = x(:);

% the order of jobs on machine 1 are:
for i=1:m
  [~,joborder(i,:)] = sort(x(:,i)');
end

% Draw this schedule:
MakeSpan = ganttch(x, p, sigma,'text')

% now lets look at an optimal trajectory up to some dispatch step
dispatchstep = 60;
[makespan_partial,xtime_partial,stime_partial,etime_partial,trajectory,lookahead,features] = jsp_data(p,sigma,x,dispatchstep);

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
% now force the different possible dispatches
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
  tag_ganttch((look(i).subx),p,sigma,'text',trajectory(1:end-1,1:2),lookahead(i,1));
  lookahead(i,1:2)
  set(gca,'xlim',[0 ceil(MakeSpan*1.2)]),
  drawnow;
  eval(sprintf('print -depsc step_%d_%d.eps', dispatchstep, i));
  %M(i) = getframe(gcf,fig_size);
  clf,
end