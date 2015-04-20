%! scp sol.raunvis.hi.is:jsp-cma/*cmarun.mat .

clear all, clc,
types={'fjc','frnd','frndn','jrnd','jrndn'}; % 'fmc','fmxc'

%%
fid = fopen('ratioRun.csv','w');
fprintf(fid, sprintf('trainingdata,obj,generation,fitness,pass\n'));
fclose(fid);

fidw = fopen('weightRun.csv','w');
fprintf(fidw, sprintf('trainingdata,obj,generation,weight,feature\n'));
fclose(fidw);

for dir = {'min_Cmax', 'min_rho'}
    for type=types
        write2csv(type{1},dir{1});
    end
end
%% training data results
fid = fopen('ratioTrain.csv','w');
fprintf(fid, 'trainingdata,obj,instance,C_max,rho\n');    
fclose(fid);
for type=types    
    for dir = {'min_Cmax', 'min_rho'}
        write2csv_training(type{1},dir{1},'cmarun-es');
    end
%    write2csv_training(type{1},'PREF','pref');       
end
%% testing data results
fid = fopen('ratioTest.csv','w');
fprintf(fid, 'trainingdata,obj,instance,C_max,rho\n');    
fclose(fid);

for type=types
    for dir = {'min_Cmax', 'min_rho'}        
        write2csv_testing(type{1},dir{1},'cmarun-es');
    end
%    write2csv_testing(type{1},'PREF','pref');   
end
