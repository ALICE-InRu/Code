% script for running the optimization experiments
randn('seed',0); rand('seed',0);
for i=1:100,
  [rosenxmin(:,i),Stats{i}.stats] = purecmaes('frosen',10);
  save p4rosen10.mat
end