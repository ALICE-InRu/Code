% experiment with 6 jobs and 5 machines on 100 randomly generated test problems
clear all
n = 11;
m = 10;
for idx=1:200, idx
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
  %params.TimeLimit = 10; % seconds?!
  result = gurobi(model, params);
  %model.vbasis = result.vbasis;
  prob(idx).result = result;
  Simplex(idx) = result.itercount;
  Optimal(idx) = result.objval;
  Runtime(idx) = result.runtime;
  params.TimeLimit = 5; % seconds?!
  subresult = gurobi(model, params);
  %model.vbasis = result.vbasis;
  prob(idx).subresult = subresult;
  SubOptimal(idx) = subresult.objval;
  nodecount(idx) = subresult.nodecount;
  prob(idx).subresult =subresult;

  
  [MakeSpanHeur(idx),~,xTime] = jspmex(prob(idx).p,prob(idx).sigma);
  
%  disp(result)
end