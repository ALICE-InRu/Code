% experiment with 6 jobs and 5 machines on 100 randomly generated test problems
clear all
n = 6;
m = 5;
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

  [makespan,xtime,~,~,seq(idx,:)] = jspmex(prob(idx).p,prob(idx).sigma,x);
  
end