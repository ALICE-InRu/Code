function write2csv_testing(name,dir,type)

load(sprintf('%s/%s-%sweights.mat',dir,name,type)); 
testpath = sprintf('../../../Scheduling/rawData/%s_10x10_Test.txt',name);
addpath ../../
testData = getproblem( testpath); 
testData=testData(501:end);

[~,~,makespan ratio] = applyglobalweights(esWeights,testData);

fid = fopen('ratioTest.csv','a');
for II=1:length(testData)
    fprintf(fid, sprintf('%s,%s,%d,%f,%f\n',name,dir,II,makespan(II),ratio(II)));    
end
fclose(fid);


end