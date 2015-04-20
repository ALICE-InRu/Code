function [generation, fitness] = getstats2(fname, batchsize, ignore),
%GETSTATS

eval(['load ' fname]);

counter = 0;
ell = length(Stats);
for i=1:ell, counter = max([counter Stats{i}.stats(end,1)]); end
number = zeros(1,counter);
%fitness = zeros(1,counter);
lots = 1:batchsize:counter;
maxlength = length(lots);
for i=1:ell,
  iterate = 1;
  bailout = 0;
  addtofront = 0;
  fitness (i,1) = Stats{i}.stats(iterate,2);
  for telja = 2:length(lots), % find a function evaluation counter smaller that that asked for
    found = 0;
    mfitness = 0;
    while (Stats{i}.stats(iterate,1) <= lots(telja))
      iterate = iterate+1;
      if (iterate > length(Stats{i}.stats))
        bailout = 0;
        if (telja < maxlength)
          maxlength = telja;
        end
        mfitness = NaN;
        break;
      else
        found = found + 1;
        mfitness = mfitness + Stats{i}.stats(iterate,2);
      end
    end
    iterate = iterate - 1;
    if (iterate == 0)
       fitness(i,telja) = NaN;
       iterate = 1;
    else
%      fitness(i,telja) = Stats{i}.stats(iterate,2);
       if (found > 0)   
	 fitness(i,telja) = mfitness / found;
       else
	 fitness (i,telja) = NaN;
       end
    end
    if (bailout == 1)
      break; 
    end
  end
end

for i = 1:size(fitness,2),
  I = find(~isnan(fitness(:,i)));
  if (~isempty(I))
    fitn(i) = mean(fitness(I,i));
  else
    fitn(i) = NaN;
  end
end
fitness = fitn;
size(fitness)
size(lots)
%fitness = mean(fitness(:,1:maxlength));
generation = lots(1:length(fitness));