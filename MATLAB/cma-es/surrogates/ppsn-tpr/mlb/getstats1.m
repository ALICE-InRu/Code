function [generation, fitness] = getstats(fname, batchsize, ignore),
%GETSTATS

eval(['load ' fname]);

counter = 0;
ell = length(Stats)
for i=1:ell, counter = max([counter Stats{i}.stats(end,1)]); end
number = zeros(1,counter);
fitness = zeros(1,counter);
lots = 1:batchsize:counter;
maxlength = length(lots);
for i=1:ell,
  iterate = 1;
  bailout = 0;
  addtofront = 0;
  for telja = 1:length(lots), % find a function evaluation counter smaller that that asked for
    while (Stats{i}.stats(iterate,1) <= lots(telja))
      iterate = iterate+1;
      if (iterate > length(Stats{i}.stats))
        bailout = 1;
        if (telja < maxlength)
          maxlength = telja;
        end
        break;
      end
    end
    iterate = iterate - 1;
    if (iterate == 0)
       fitness(i,telja) = NaN;
       iterate = 1;
    else
      fitness(i,telja) = Stats{i}.stats(iterate,2);
    end
    if (bailout == 1)
      break; 
    end
  end
end

fitness = mean(fitness(:,1:maxlength));
generation = lots(1:maxlength);