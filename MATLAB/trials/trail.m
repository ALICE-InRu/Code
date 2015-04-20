% experiment with 6 jobs and 5 machines on 100 randomly generated test problems
clear all
n = 10;
m = 9;
for idx=1:100, idx
  data = ceil(100*rand(n,2*m));
  for i=1:n
    data(i,1:2:end-1) = randperm(m)-1;
  end
  prob(idx).p = data(:,2:2:end);
  prob(idx).sigma = data(:,1:2:end)+1;
  
  model = jssp_gurobi_model(prob(idx).p,prob(idx).sigma);
  clear params;
  params.outputflag = 0;
  params.Threads = 4;
  %params.TimeLimit = 100; % seconds?!
  result = gurobi(model, params);
  prob(idx).result = result;
  Simplex(idx) = result.itercount;
  Optimal(idx) = result.objval;
  Runtime(idx) = result.runtime;
  
  % now in what sequence are the jobs scheduled on a machine?
  %[n m] = size(p);
  x = result.x(1:n*m);
  x = reshape(x,n,m);
  
  % the order of jobs on machine i are:
  for i=1:m
    [~,optjoborder(i,:)] = sort(x(:,i)');
  end
  % Draw this schedule:
%  MakeSpan = ganttch(x, p, sigma,'text')
  [MakeSpanHeur(idx,:),xTime] = jspmex(prob(idx).p,prob(idx).sigma);
  % the order of jobs on machine i are:
  TAU(idx) = 0;
  for i=1:m
    [~,joborder(i,:)] = sort(xTime(:,i)');
     TAU(idx) = TAU(idx) + kendalltau(optjoborder(i,:),joborder(i,:));
  end
  % when all jobs are ordered
  diff = x-xTime;
  XDIFF(idx) = norm(diff(:));
%  disp(result)
end