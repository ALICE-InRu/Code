function [model2,label_predict,label_decisionvalue]= train2(training,featuresInUse,instancesInUse,reportClassificationAcc,reportStepwiseAcc)
[NumInstances,NrFeat]=size(training.instance_matrix);
if(nargin<2), featuresInUse=1:NrFeat; end
if(nargin<3 | isempty(instancesInUse)), instancesInUse=1:NumInstances; end % used in adaboost.m
if(nargin<4), reportClassificationAcc=true; end
if(nargin<5), reportStepwiseAcc=true; end
%% Liblinear parameters
liblinear_options='-c 10 -s 6'; 
if(computer=='PCWIN64')
    addpath ..\liblinear-1.94\windows\
else
    addpath ../liblinear-1.94/matlab/
end

%%
model=train(training.label_vector(instancesInUse), training.instance_matrix(instancesInUse,featuresInUse), liblinear_options);
if model.Label(1)==1
    model.Label=model.Label*-1;
    model.w=model.w.*-1;
    % for stepwiseTrainingAccuracy to work
end

if model.bias < 0
    %if bias >= 0, instance x becomes [x; bias]; if < 0, no bias term added (default -1)
    model.bias = 0; 
end

% model.training_accuracy=predict2(training,model,featuresInUse);
%%
model2=model;
model2.w=zeros(1,NrFeat);
model2.w(featuresInUse)=model.w;
model2.nr_feature=NrFeat;

if nargout>1 | reportClassificationAcc
    [model2.training_accuracy_stepwise,model2.training_accuracy_classification,label_predict,label_decisionvalue] = predict2(training,model2);
elseif reportStepwiseAcc
    model2.training_accuracy_stepwise = predict2(training,model2);
end

end