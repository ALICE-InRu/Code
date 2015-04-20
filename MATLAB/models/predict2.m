function [stepwise_acc,classification_acc,label_predict,label_decisionvalue] = predict2(data,model,featuresInUse)

if(nargin==3)
    instance_matrix=data.instance_matrix(:,featuresInUse);
else
    instance_matrix=data.instance_matrix;
end

if isfield(data,'opt_track')
    stepwise_acc=stepwiseTrainingAccuracy(data,[],model)*100;    
else
    stepwise_acc=-1;
end

if nargout > 1
    [label_predict,accuracy,label_decisionvalue] = predict(data.label_vector, instance_matrix, model);
    classification_acc=accuracy(1);
end

end
