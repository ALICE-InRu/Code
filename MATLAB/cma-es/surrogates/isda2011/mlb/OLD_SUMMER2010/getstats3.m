function [generation, intmEval, funcEvals, fitness, finEvals, finGen, finFit] = getstats3(fname),

%GETSTATS

eval(['load ' fname]);

maxEval=0; maxGen=0;
ell = length(Stats); % Number of simulations
for i=1:ell, maxGen = max([maxGen length(Stats{i}.stats(:,1))]); end
for i=1:ell, maxEval = max([maxEval Stats{i}.stats(end,1)]); end

generation=1:maxGen;

%% Fitness values between generations
%{
fitness = ones(ell,maxGen).*NaN;
for i=1:ell,
  fitness(i,1:length(Stats{i}.stats(:,1))) = Stats{i}.stats(:,2);
end
% Mean fitness (weighted by where it's a real number)
for i=1:maxGen
  mfitness(i) = mean(fitness(find(~isnan(fitness(1:ell,i))),i));
end
fitness=mfitness;
%}
%% Fitness values between func. evaluations
fitness = ones(ell,maxEval).*NaN;
for i=1:ell,
  fitness(i,Stats{i}.stats(:,1))=Stats{i}.stats(:,2);
  finEvals(i)=Stats{i}.stats(end,1);
  finFit(i)=Stats{i}.stats(end,2);
  finGen(i)=length(Stats{i}.stats(:,2));
end
% Mean fitness (weighted by where it's a real number)
for i=1:maxEval
  mfitness(i) = mean(fitness(find(~isnan(fitness(1:ell,i))),i));
end
funcEvals=find(~isnan(mfitness));
fitness=mfitness(funcEvals); 

%% Intermediate values between generations 
intmEval = ones(ell,maxGen).*NaN;
for i=1:ell
  intmEval(i,1:length(FCNEVAL{i})) = FCNEVAL{i};
  finFunc(i)=sum(FCNEVAL{i});
end
% Mean intermediate values (weighted by where it's a real number)
for i=1:maxGen
  mintmEval(i) = mean(intmEval(find(~isnan(intmEval(1:ell,i))),i));
end
intmEval=mintmEval;
