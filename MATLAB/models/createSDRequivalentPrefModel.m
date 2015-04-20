function [sdrModel,validation_accuracySDR]=createSDRequivalentPrefModel(SDR,distr,dim,track,type,rank)
if(nargin<6) rank='p'; end
if(nargin<5) type='Local'; end
if(nargin<4) track='OPT'; end
if(nargin<3) dim='10x10'; end
if(nargin<2) distr='j.rnd'; end
if(nargin<1) SDR='MWR'; end
%%
[testing_instance_matrix,weights,allFeatures]=diffcsv2mat(distr,dim,track,rank,type);
testing_label_vector=sign(weights);
%%
if strcmpi(SDR,'MWR') 
    signWeight=1;
    activeFeatures='phi.wrmJob';
elseif strcmp(SDR,'LWR')
    signWeight=-1;
    activeFeatures='phi.wrmJob';
elseif strcmp(SDR,'LPT')
    signWeight=1;
    activeFeatures='phi.proc';
elseif strcmpi(SDR,'SPT')
    signWeight=-1;
    activeFeatures='phi.proc';
else
    error('Unknown SDR');
end     
%%
featuresInUse=find(strcmp(allFeatures,activeFeatures));
sdrModel.w = zeros(1,length(allFeatures));
sdrModel.w(featuresInUse)=signWeight;
%%
pred_estimates = testing_instance_matrix*sdrModel.w';
pred = sign(pred_estimates);
validation_accuracySDR = mean(pred==testing_label_vector);
disp(sprintf('Accuracy for %s on full training data: %.2f',SDR,validation_accuracySDR));

end
