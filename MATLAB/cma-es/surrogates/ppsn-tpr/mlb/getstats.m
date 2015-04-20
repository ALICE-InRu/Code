function [G, F] = getstats(fname, batchsize, ignore),
%GETSTATS

eval(['load ' fname]);

counter = 0;
ell = length(Stats)
for i=1:ell, counter = max([counter Stats{i}.stats(end,1)]); end
number = zeros(1,counter);
fitness = zeros(1,counter);
for i=1:ell,
  if (Stats{i}.stats(end,2) < ignore)
    position = Stats{i}.stats(:,1)'; 
    values = Stats{i}.stats(:,2)'; 
    number(position) = number(position) + 1;
    fitness(position) = fitness(position) + values;
  else
    disp('local minima ignored in stats');
    Stats{i}.stats(end,2), 
  end
end

%I = find(number > 0);
%fitness(I) = fitness(I) ./number(I);
%fitness = fitness / ell; %./number(I);
%generation = I;

histo = [1 10:batchsize:counter]; if (histo(end) < counter), histo = [histo counter]; end
F = []; G = [];
for i = 1:(length(histo)-1),
  I = find(number(histo(i):histo(i+1)) > 0);
  if ~isempty(I),
%    F = [F mean(fitness(I+histo(i)-1))];
    F = [F sum(fitness(I+histo(i)-1))/sum(number(I+histo(i)-1))];
    G = [G (histo(i)+histo(i+1))/2-1];
  end
end
