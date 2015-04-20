%clear all, close all
%problems  = getproblem('../Scheduling/rawData/jrnd_10x10_Train.txt');
%[n,m] = size(problems(1).p);
load JRNDTRAINDATA10x10.mat; n=10; m=10;

MWR_IS_OPTIMAL = zeros(1,n*m);
for IDNUM = 1:length(DAT), IDNUM
  dat = DAT(IDNUM).dat;
  optimal = min(dat(:,2));
  for i=1:n*m
    data = dat((i==dat(:,1)),:);
    optidx = find(data(:,2) == optimal);
    wrmidx = find(data(:,5) == max(data(:,5)));
    if ~isempty(wrmidx)
      if any(wrmidx(1)==optidx)
        MWR_IS_OPTIMAL(i) = MWR_IS_OPTIMAL(i)+1;
      end
    else
      MWR_IS_OPTIMAL(i) = MWR_IS_OPTIMAL(i)+1;
    end
  end
end
MWR_IS_OPTIMAL = MWR_IS_OPTIMAL/length(DAT);

plot(MWR_IS_OPTIMAL,'.')
set(gca,'ylim',[0 1])
grid
xlabel('step')
ylabel('Prob of selecting the optimal path usin MWRM');
title('10x10 problem');
 