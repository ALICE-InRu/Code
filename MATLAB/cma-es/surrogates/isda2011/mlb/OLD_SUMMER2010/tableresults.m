
strfitnessfct = 'fsphere';
%strfitnessfct = 'frosen';
for i=1:4*2, tmpname{i}=sprintf(['matResults/' strfitnessfct '%d.mat'],i); end
m=0;
allfinEvals=zeros(8,100);
allFinFit=zeros(8,100);
allFinGen=zeros(8,100);
disp([ strfitnessfct ' & function evaluations & generations & fitness'])
disp('policy & N & mean & median & std & mean & median & std & mean & median & std')
for i = 1, % the function type
  for N = [2 5 10 20], % the dimension
    for T = [1,6], % model type
      m=1+m;
      fname=sprintf(['matResults/' strfitnessfct '%d_d%d.mat'],T,N);
      [generation, intmEval, funcEvals, fitness,finEvals,finGen,finFit] = getstats3(fname);
      smoothFitness = smooth(funcEvals, fitness,100);
      smoothIntmEval = smooth(generation, intmEval,100);
      save(tmpname{m},'generation', 'intmEval', 'funcEvals', 'fitness','smoothFitness','smoothIntmEval','finFit','finGen')
      fprintf('%d & %d & %.2f & %.0f & %.2f & %.2f & %.0f & %.2f & %.2e & %.2e & %.2e\\\\ \n',T,N,mean(finEvals),median(finEvals),std(finEvals),mean(finGen),median(finGen),std(finGen),mean(finFit),median(finFit),std(finFit))
      allFinGen(m,1:100)=finGen;
      allFinEvals(m,1:100)=finEvals;
      allfinFit(m,1:100)=finFit;
      outlaw(m)=length(find(finFit>1e-8));
    end
  end
  fprintf('\n');
end

