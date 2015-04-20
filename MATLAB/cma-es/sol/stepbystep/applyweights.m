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
function [meanMakespan meanRatio] = applyweights(weights)

global numFeatures rawData
% If these are not GLOBAL variables, then uncomment:
% numFeatures=13; % ! Needs to be edited
% load('rawData/Uniform10x100_n6xm5/train.mat') % ! Needs to be edited

% Bruteforce approach
[numJobs,numMacs]=size(rawData(1).p);dim2=numJobs*numMacs;    
model = linear2model(weights,dim2,numFeatures); % Translate the weights into a model
[makespan ratio]=SLLPDR(model,rawData); % Apply the model on the training problem instances
meanMakespan=mean(makespan); % report the mean makespan
meanRatio=mean(ratio); % not used - cheating?

end

function model = linear2model(weights,dim2,numFeatures)
model(dim2).w=[];
model(dim2).b=[];
next=0;
for step=1:dim2
  now=next+1;
  next=now+numFeatures;
  model(step).w(1:numFeatures)=weights(now:next-1);
  model(step).b=next;
end
end