function [model] = adaboost(training, featuresInUse, maxIter)
%% definitions
ell = length(training.label_vector);
we = ones(ell,1)/ell;
if (nargin<3), maxIter=1000; end

%% plot the data
displayPlot = false & size(training.instance_matrix,2)==2;
if(displayPlot)
    hold off
    plot(training.instance_matrix(training.label_vector==1,1),training.instance_matrix(training.label_vector==1,2),'b*',training.instance_matrix(training.label_vector==-1,1),training.instance_matrix(training.label_vector==-1,2),'r*')
    hold on
end

%% Boosting
iter=1;
while (iter <= maxIter) % perhaps we should have a maximum step size
    disp(sprintf('Boosting iteration %d ....................',iter));
    %% Bagging, sample with replacement with probability we training data    
    instancesInUse = randsample(ell,ell,true,we);
    
    %% Use the LIBLINEAR to find (w,b) classifier
    [liblinearModel] = train2(training,featuresInUse,instancesInUse,0,0);    
    W(iter,1:liblinearModel.nr_feature)=liblinearModel.w;
    B(iter)=liblinearModel.bias;    
    %% display the SVM plane at zero
    if ~all(liblinearModel.w==0)
        if(displayPlot)
            plotPlane(liblinearModel.w,liblinearModel.bias);
        end
    else
        % now this is a rather silly stop critera, but what the ...
        break;
    end
    %% the pseudocode for this may be found here:http://en.wikipedia.org/wiki/AdaBoost
    Err(iter) = sum(-training.label_vector.*sign(training.instance_matrix*W(iter,:)'+B(iter)).*we); % the weighted error
    Alpha(iter) = (1/2)*log((1-Err(iter))/(1+Err(iter))); % update on alpha
    we = we.*exp(-Alpha(iter)*training.label_vector.*sign(training.instance_matrix*W(iter,:)'+B(iter))); % update the weights
    we = we/sum(we); % and normalize probabilities
    %WE(t,:) = we; % OUT OF MEMORY
    %% next iter
    iter = iter + 1;
end
model=struct('alpha',Alpha,'W',W,'B',B,'Err',Err)
end

function plotPlane(w,b)
x1(1) = 10;   x2(2) = 10; x2(1) = (-b-w(1)*x1(1))/w(2);  x1(2) = (-b-w(2)*x2(2))/w(1);
plot(x1,x2,':'), set(gca,'ylim',[0 10],'xlim',[0 10])
end