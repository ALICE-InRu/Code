function write2csv_training(name,dir,type)

load(sprintf('%s/%s-%sweights.mat',dir,name,type)); 
load(sprintf('%s-rawtrain.mat',name));

[meanRatio meanMakespan makespan ratio] = applyglobalweights(esWeights,rawData);

fid = fopen('ratioTrain.csv','a');
for II=1:length(rawData)
    fprintf(fid, sprintf('%s,%s,%d,%f,%f\n',name,dir,II,makespan(II),ratio(II)));    
end
fclose(fid);


end