function [reducedModel,fullModel,activeFeatures, allFeatures]=createReducedPrefModel(distr,dim,track,type,rank,diffAcc)
if(nargin<6) diffAcc=1; end
if(nargin<5) rank='p'; end
if(nargin<4) type='Local'; end
if(nargin<3) track='OPT'; end
if(nargin<2) dim='10x10'; end
if(nargin<1) distr='j.rnd'; end

useDiff = 0; 
%addpath ../liblinear-1.94/matlab/
addpath C:\Users\helga\Toolbox\liblinear-1.94\matlab
%%
[instance_matrix,weights,allFeatures]=csv2mat(distr,dim,track,type,0,useDiff,rank);
save debug; 
return

if(isempty(instance_matrix) | isempty(weights))
    activeFeatures=[];
    fullModel=[];
    reducedModel=[];
    return;
end

label_vector=sign(weights);
instance_matrix=sparse(instance_matrix);
N=length(label_vector);
Ntrain=round(N*0.5);

trainon=sort(randsample(N,Ntrain));
teston=setdiff(1:N,trainon);

training_label_vector = label_vector(trainon);
training_instance_matrix = instance_matrix(trainon,:);

testing_label_vector = label_vector(teston);
testing_instance_matrix = instance_matrix(teston,:);

%% Liblinear parameters
liblinear_options='-c 10 -s 6'; % 6 -- L1-regularized logistic regression

%% Benchmark model, using all features
fullModel = train(training_label_vector, training_instance_matrix , liblinear_options);
[~, training_accuracyFull,~] = predict(training_label_vector, training_instance_matrix, fullModel);
[~, validation_accuracyFull,~] = predict(testing_label_vector, testing_instance_matrix, fullModel);

%% drop 1
featuresInUse=1:size(instance_matrix,2);
%%
while(1)
    skipping=[];
    for skip=featuresInUse
        newFeatures=setdiff(featuresInUse,skip);
        rmodel = train(training_label_vector, training_instance_matrix(:,newFeatures) , liblinear_options);
        [~,validation_accuracyReduced,~] = predict(testing_label_vector, testing_instance_matrix(:,newFeatures), rmodel);
        skipping=[skipping validation_accuracyReduced(1)];
    end
    [best_acc,id]=max(skipping);
    if(best_acc>validation_accuracyFull(1)-diffAcc)
        skip=featuresInUse(id);
        fprintf('Skipping feature %d, with acc %.2f\n',skip,best_acc)
        featuresInUse=setdiff(featuresInUse,skip);
    else
        break;
    end
end
%% Reduced model
rmodel = train(training_label_vector, training_instance_matrix(:,featuresInUse) , liblinear_options);
[~, training_accuracyReduced,~] = predict(training_label_vector, training_instance_matrix(:,featuresInUse), rmodel);
[~, validation_accuracyReduced,~] = predict(testing_label_vector, testing_instance_matrix(:,featuresInUse), rmodel);

%% format model
activeFeatures = allFeatures(featuresInUse);
reducedModel.w = zeros(1,fullModel.nr_feature);
reducedModel.w(featuresInUse)=rmodel.w;

%% print to screen
clc;
disp(sprintf('Original (full) training accuracy: %.2f',training_accuracyFull(1)))
disp(sprintf('Original (full) valdation accuracy: %.2f',validation_accuracyFull(1)))
disp(sprintf('------> Reduction: from %d to %d features',length(allFeatures),length(activeFeatures)));
disp(sprintf('Original reduction training accuracy: %.2f',training_accuracyReduced(1)))
disp(sprintf('Original reduction valdation accuracy: %.2f',validation_accuracyReduced(1)))
disp(activeFeatures)

%% save
fname=sprintf('reduced.model.%s.%s.%s.%s.%s.mat',distr,dim,track,rank,type);
save(fname);

end


function ix = randsample(Nall,Nuse)

ix = randperm(Nall);
ix = ix(1:Nuse);

end