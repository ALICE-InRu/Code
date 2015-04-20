% script for running the optimization experiments
randn('seed',0); rand('seed',0);
for i=1:100,
  [rosenxmin(:,i),Stats{i}.stats] = purecmaes('frosen',20);
  save p4rosen20.mat
end