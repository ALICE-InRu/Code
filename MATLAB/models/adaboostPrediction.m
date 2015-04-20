function [yhat,acc]=adaboostPrediction(model,data)

for t = 1:length(model.alpha)
    yhatall(:,t)=model.alpha(t)*sign(data.instance_matrix*model.W(t,:)'+model.B(t));
end
yhat = sign(sum(yhatall,2));

if nargout>1
    acc = mean(yhat==data.label_vector)*100;
else 
    acc = -1;
end

end