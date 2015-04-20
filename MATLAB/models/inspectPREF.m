function [training,testing,PREF]=inspectPREF(distr,dim,track,rank,weightType,scaledModel,showPlot,overwrite)
if nargin<1, distr='j.rnd'; end
if nargin<2, dim='10x10'; end
if nargin<3, track='OPT'; end
if nargin<4, rank='p'; end
if nargin<5, weightType='equal'; end
if nargin<6, scaledModel=false; end
if nargin<7, showPlot=false; end
if nargin<8, overwrite=false; end
close all
%% get data
[training,validation,testing]=csv2mat(distr,dim,track,'Local',rank);
PREF = getLiblinearModelsFromR(distr,dim,rank,track,scaledModel,weightType);
[pathstr,name,ext] = fileparts(PREF.weightFile);
fname=sprintf('%s/optStepwiseAcc/%s.MATLAB%s',pathstr,name,ext);
if exist(fname,'file') & ~overwrite
    warning('Already exists, return');
    return
end

%% check stepwise accuracy
[training.mean_acc,training.stepwise_acc] = stepwiseTrainingAccuracy(training,PREF,[],showPlot);
[validation.mean_acc,validation.stepwise_acc] = stepwiseTrainingAccuracy(validation,PREF,[],showPlot);
if ~isempty(testing)
    [testing.mean_acc,testing.stepwise_acc] = stepwiseTrainingAccuracy(testing,PREF,[],showPlot);
end
%% save results
if ~exist(fname,'file') | overwrite
    saveToCsvLiblinear(PREF,fname,training,validation,testing)
end

end

function saveToCsvLiblinear(PREF,fname,training,validation,testing)
[NrSteps,NrModels]=size(training.stepwise_acc);
if(NrModels~=PREF.nr_models) error('stepwiseTrainingAccuracy was not run right'); end
testAcc='NA';
fid = fopen(fname,'w'); %# Open the file
if fid ~= -1
    fprintf(fid,'NrFeat,Model,Step,train.isOptimal,validation.isOptimal,test.isOptimal\r\n');
    for MID=1:PREF.nr_models
        for Step=1:NrSteps
            if ~isempty(testing) testAcc=sprintf('%.4f',testing.stepwise_acc(Step,MID)); end                
            fprintf(fid,sprintf('%d,%d,%d,%.4f,%.4f,%s\r\n',...
                PREF.Model{MID}.NrFeat,...
                PREF.Model{MID}.NrModel,...
                Step,...
                training.stepwise_acc(Step,MID),...
                validation.stepwise_acc(Step,MID),...
                testAcc));
        end
    end
    fclose(fid);                     %# Close the file
end
end

