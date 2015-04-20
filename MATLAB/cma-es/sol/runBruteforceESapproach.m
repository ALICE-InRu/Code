% [meanMinMakespan esWeights]=bruteforceESapproach;
clear all, clc
data='Uniform10x100_n6xm5';

%% ! scp jotunn.rhi.hi.is:jssp/jsspES.mat .
fname=['../trainingData/' data '/jotunn_cmaes_allvar'];
load([fname '.mat'])
%% Finish the purecmaes.m
disp([num2str(counteval) ': ' num2str(arfitness(1))]);
xmin = arx(:, arindex(1)); % Return best point of last iteration.
% Notice that xmean is expected to be even
% better.
figure(1); hold off; semilogy(abs(out.dat)); hold on;  % abs for negative fitness
semilogy(out.dat(:,1) - min(out.dat(:,1)), 'k-');  % difference to best ever fitness, zero is not displayed
title('fitness, sigma, sqrt(eigenvalues)'); grid on; xlabel('iteration');
figure(2); hold off; plot(out.datx);
title('Distribution Mean'); grid on; xlabel('iteration')
esWeights=xmin;

%% Convert the weights to a model
[meanMakespan esModel ratio makespan] = applyweights(esWeights);
save([fname(1:end-7) '.mat'],'esModel','meanMakespan','ratio','makespan');
warning('Remember to re-run all dependant runs')