%   BRUTEFORCE SEARCH USING CMA-ES TO FIND OPTIMAL WEIGHTS FOR LINEAR
%   ORD.REG.MODEL - inner function
%   [meanMakespan model] = applyweights(weights)
%  
%   input:  param weights, a vector of length numFeatures*dim2+dim2
%       ---> Following param need to be edited prior to run
%         * param numFeatures, number of features (same as in: getFeatures.m)
%         * param datadistr, type of datadistribution, 
%                 e.g. rawData/Uniform10x100_n6xm5/train.mat
%  
%   output: var meanMakespan, mean makespan of problem instances for given weights
%             model, linear model with given weights
%   
%   dependant files: SLLPDR.m (and thus also getFeatures.m jsp_ch.m)
function [meanRatio meanMakespan makespan ratio] = applyglobalweights(weights,rawData)

global numFeatures rawData
% If these are not GLOBAL variables, then uncomment:
% numFeatures=13; % ! Needs to be edited
% load('rawData/Uniform10x100_n6xm5/train.mat') % ! Needs to be edited

% Bruteforce approach
model = linear2model(weights,numFeatures); % Translate the weights into a model
[makespan ratio]=SLLPDRglobal(model,rawData); % Apply the model on the training problem instances
meanMakespan=mean(makespan); % report the mean makespan
meanRatio=mean(ratio); % not used - cheating?

end

function model = linear2model(weights,numFeatures)
  model.w(1:numFeatures)=weights(1:numFeatures);
  model.b=weights(numFeatures+1);
end