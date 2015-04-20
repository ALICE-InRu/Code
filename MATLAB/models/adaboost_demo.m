clear all, close all;
%% data 
X = [3 7;4 6;5 6;7 7;8 5;4 5;5 5;6 3;7 4;9 4];
y = [-1 1 1 1 1 -1 -1 -1 -1 -1]';
training=struct('instance_matrix',sparse(X),'label_vector',y,'NumInstances',length(y),'Name','debug');
if exist('debug.mat','file'), delete debug.mat; end
%% apply adaboost 
model = adaboost(training, 1:2, 100);
[yhat,acc]=adaboostPrediction(model,training);
%saveas(gcf,'adaboost_demo.png')
%% Comparison
singleModel = train2(training);
disp(sprintf('Adaboost training accuracy: %d',acc)); 
disp(sprintf('Single pass training accuracy: %d',singleModel.training_accuracy)); 
