clear all, clc,
addpath ../
m=1;
for it=1:8
  fname=sprintf('rosen%d.mat',it);
  [a,b,c,d, finEvals, finGen, finFit] = getstats3(fname);
  load(fname);
  if ismember(it,[1 2 4 6 8])
      compRosen(1:100,m)=finEvals;
      m=m+1;
  end
  end