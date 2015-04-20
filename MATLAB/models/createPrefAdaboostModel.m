function adaboostModel=createPrefAdaboostModel(distr,NrFeat,Model,dim,track,type,rank,boostingIter)
if(nargin<8) boostingIter=100; end
if(nargin<7) rank='p'; end
if(nargin<6) type='Local'; end
if(nargin<5) track='OPT'; end
if(nargin<4) dim='10x10'; end
if(nargin<3) Model=549; end 
if(nargin<2) NrFeat=3; end
if(nargin<1) distr='j.rnd'; end
%% get data 
[training,testing,allFeatures]=csv2mat(distr,dim,track,type,rank);
%% for comparison: full and reduced, i.e. single pass adaboost, models
[reducedModel,fullModel,featuresInUse]=readReducedPrefModel(distr,NrFeat,Model,dim,track,type,rank,training,testing,allFeatures);
%% apply adaboost
adaboostModel = adaboost(training,featuresInUse,boostingIter);
%% now classify your complete data set or some test set using ensemble model
[~,adaboostModel.training_accuracy]=adaboostPrediction(adaboostModel,training);
[~,adaboostModel.testing_accuracy]=adaboostPrediction(adaboostModel,testing);
%% print to screen
clc;
disp(sprintf('Original (full) training accuracy: %.2f',fullModel.training_accuracy_classification))
disp(sprintf('Original reduction training accuracy: %.2f',reducedModel.training_accuracy_classification))
disp(sprintf('Adaboost training accuracy: %.2f',adaboostModel.training_accuracy))

disp(sprintf('Original (full) valdation accuracy: %.2f',fullModel.testing_accuracy_classification))
disp(sprintf('Original reduction valdation accuracy: %.2f',reducedModel.testing_accuracy_classification))
disp(sprintf('Adaboost training valdation: %.2f',adaboostModel.testing_accuracy))

%% save model 
fnameAdaboost=sprintf('adaboost.model.%s.%s.%s.%s.%s.%s.mat',distr,dim,track,rank,type,NrFeat_Model);
save(fnameAdaboost);
end