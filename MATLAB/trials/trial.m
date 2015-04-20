% question: what is it that makes the JSP problem hard?
clear all
n = 9;
m = 8;
for idx=1:100, idx
  data = ceil(100*rand(n,2*m));
  for i=1:n
    data(i,1:2:end-1) = randperm(m)-1;
  end
  prob(idx,1).p = data(:,2:2:end);
  prob(idx,1).sigma = data(:,1:2:end)+1;
  for repeat = 1:21
    p = prob(idx,1).p;
    sigma = prob(idx,1).sigma;
    % add small noise to the processing times 5%:
    if (repeat > 1)
      % only mutate one of the jobs:
      job = ceil(rand(1)*n);
      mac = ceil(rand(1)*m);
      %p = p + rand(size(p)).*p/20;
      %p(job,mac) = ceil(rand(1)*100);
      sigma(job,:) = randperm(m); % shuffle machine order for one job
    end
    model = jssp_gurobi_model(p,sigma);
    clear params;
    params.outputflag = 0;
    params.Threads = 4;
    %params.TimeLimit = 100; % seconds?!
    result = gurobi(model, params);
    prob(idx,repeat).result = result;
    Simplex(idx,repeat) = result.itercount;
    Optimal(idx,repeat) = result.objval;
    Runtime(idx,repeat) = result.runtime;
  end
end
