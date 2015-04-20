function write2csv(name, dir)

fid = fopen('ratioRun.csv','a');
fidw = fopen('weightRun.csv','a');
load(sprintf('%s/%s-cmarun.mat',dir,name));

%% ------------- Final Message and Plotting Figures --------------------
disp(sprintf('%s & %d & %d & %.3f',name,length(out.dat),counteval,arfitness(1)));
xmin = arx(:, arindex(1)); % Return best point of last iteration.
% Notice that xmean is expected to be even
% better.

%   figure(1); subplot(1,2,1), hold off; semilogy(abs(out.dat(:,1:2))); hold on;  % abs for negative fitness
%   semilogy(out.dat(:,1) - min(out.dat(:,1)), 'k-');  % difference to best ever fitness, zero is not displayed
%   legend({'fitness','sigma','difference'},'location','best'); grid on; xlabel('iteration');
%   title(usenow)
%
%   figure(1), subplot(1,2,2), semilogy(abs(out.dat(:,3:16)));
%   ylabel('sqrt(eigenvalues)'); grid on; xlabel('iteration');
%   %legend({'w_1' 'w_2' 'w_3' 'w_4' 'w_5' 'w_6' 'w_7' 'w_8' 'w_9' 'w_{10}' 'w_{11}' 'w_{12}' 'w_{13}' 'b' },'location','NorthEastOutside')

for II=1:length(out.dat)
    fprintf(fid, sprintf('%s,%s,%d,%f,%f\n',name,dir,II,out.dat(II,1:2)));
    normweights=out.datx(II,1:numFeatures);
    normweights=normweights/norm(normweights);
    for III=1:numFeatures
        fprintf(fidw, sprintf('%s,%s,%d,%f,%d\n',name,dir,II,normweights(III),III));
    end
end
%
%   figure(2); hold off; plot(out.datx);
%   title([ usenow '   Distribution Mean']); grid on; xlabel('iteration')
%   legend({'w_1' 'w_2' 'w_3' 'w_4' 'w_5' 'w_6' 'w_7' 'w_8' 'w_9' 'w_{10}' 'w_{11}' 'w_{12}' 'w_{13}' 'b' },'location','NorthEastOutside')
%
esWeights=xmin;
esWeights=esWeights/norm(esWeights);
save(sprintf('%s/%s-esweights',dir,name),'esWeights')

writeweights2csharp(name(1),name(2:end),dir,esWeights,datestr(now),length(out.dat),counteval,arfitness(1))

%%
fclose(fid);
fclose(fidw);

end