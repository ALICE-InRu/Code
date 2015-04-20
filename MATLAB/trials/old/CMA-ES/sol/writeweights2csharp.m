function writeweights2csharp(shop,distr,obj,weights,date,numGen,numEval,bestEval)


%%

path='C:\Users\helga\PhD\Code\Scheduling\wip';
name=sprintf('%s%s',shop,distr);
fid = fopen(sprintf('%s/model.%s.%s.CMAES.%s.txt',path,shop,distr,obj),'w');

fprintf(fid,sprintf('CMA-ES results: %s\r\n',date));
fprintf(fid,sprintf('Training data: %s.%s\r\n',shop,distr));
fprintf(fid,sprintf('Total generations: %d\r\n',numGen));
fprintf(fid,sprintf('Total fitness evaluations: %d\r\n',numEval));
fprintf(fid,sprintf('Best objective value: %f\r\n',bestEval));

fprintf(fid,'\r\n\r\nWeights:\r\n');
fprintf(fid,'phi.proc %f\r\n',weights(1));
fprintf(fid,'phi.startTime %f\r\n',weights(2));
fprintf(fid,'phi.endTime %f\r\n',weights(3));
fprintf(fid,'phi.wrmJob %f\r\n',weights(6));
%fprintf(fid,'phi.mwrm %f\r\n',weights(7));
fprintf(fid,'phi.totproc %f\r\n',weights(13));
fprintf(fid,'phi.wait %f\r\n',weights(11));
fprintf(fid,'phi.macfree %f\r\n',weights(4));
fprintf(fid,'phi.makespan %f\r\n',weights(5));
fprintf(fid,'phi.slotReduced %f\r\n',-weights(12));
fprintf(fid,'phi.slots %f\r\n',weights(8));
fprintf(fid,'phi.slotsTotal %f\r\n',weights(9));
%fprintf(fid,'phi.slotsTotalPerOp %f\r\n',weights(10));
%fprintf(fid,'phi.MWR 0\r\n');
%fprintf(fid,'phi.LWR 0\r\n');
%fprintf(fid,'phi.SPT 0\r\n');
%fprintf(fid,'phi.LPT 0\r\n');
%fprintf(fid,'phi.RNDmean 0\r\n');
%fprintf(fid,'phi.RNDstd 0\r\n');
%fprintf(fid,'phi.RNDmin 0\r\n');
%fprintf(fid,'phi.RNDmax 0\r\n');

fprintf(fid,'\r\n\r\nEnd of file');
fclose(fid);

